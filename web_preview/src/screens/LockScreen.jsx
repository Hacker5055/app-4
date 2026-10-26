import React, { useState, useEffect, useRef } from 'react'
import { Shield, Fingerprint, Lock, Science, Eye, Trash, Warning, Check, CheckCircle } from '../Icons.jsx'

const KEYPAD = [
  ['1', ''], ['2', 'ABC'], ['3', 'DEF'],
  ['4', 'GHI'], ['5', 'JKL'], ['6', 'MNO'],
  ['7', 'PQRS'], ['8', 'TUV'], ['9', 'WXYZ'],
  ['clear', ''], ['0', '+'], ['back', ''],
]

export default function LockScreen({ pins, hasPins, mockMode, onConfig, onMaster, onDuress, onToast, setupDone }) {
  const [pin, setPin] = useState('')
  const [error, setError] = useState(false)
  const [message, setMessage] = useState(null)
  const [fails, setFails] = useState(0)
  const [lockout, setLockout] = useState(0)
  const [busy, setBusy] = useState(false)
  const timer = useRef(null)

  // first-launch wizard state
  const [setup, setSetup] = useState(hasPins ? null : 'master')
  const [pendingMaster, setPendingMaster] = useState('')
  const [pendingDuress, setPendingDuress] = useState('')
  const [pendingAction, setPendingAction] = useState(2)

  useEffect(() => {
    if (lockout > 0) {
      const t = setTimeout(() => setLockout((v) => v - 1), 1000)
      return () => clearTimeout(t)
    }
  }, [lockout])

  useEffect(() => () => clearTimeout(timer.current), [])

  const flash = (msg, isErr = true, ms = 2400) => {
    setMessage(msg)
    setError(isErr)
    clearTimeout(timer.current)
    timer.current = setTimeout(() => {
      setError(false)
      setMessage(null)
      setPin('')
    }, ms)
  }

  const submit = (value) => {
    if (busy) return
    if (setup === 'master') {
      setPendingMaster(value)
      setSetup('duress')
      setPin('')
      return
    }
    if (setup === 'duress') {
      if (value === pendingMaster) {
        flash('Duress PIN must differ from Master PIN')
        return
      }
      setPendingDuress(value)
      setSetup('action')
      setPin('')
      return
    }

    if (lockout > 0) {
      flash(`Locked — retry in ${lockout}s`)
      return
    }

    setBusy(true)
    setTimeout(() => {
      if (value === pins.duress) {
        onDuress()
      } else if (value === pins.master) {
        onMaster()
      } else {
        const next = fails + 1
        setFails(next)
        setBusy(false)
        if (next >= 5) {
          setLockout(30)
          flash('Too many attempts — locked for 30 seconds')
        } else {
          flash(`Incorrect PIN — ${5 - next} attempts remaining`)
        }
      }
      setPin('')
    }, 380)
  }

  const press = (k) => {
    if (busy || lockout > 0) return
    if (k === 'clear') return setPin('')
    if (k === 'back') return setPin((p) => p.slice(0, -1))
    if (pin.length >= 6) return
    const next = pin + k
    setPin(next)
    if (next.length === 6) setTimeout(() => submit(next), 140)
  }

  const finishSetup = () => {
    setupDone({ master: pendingMaster, duress: pendingDuress, action: pendingAction })
    setSetup(null)
    setPin('')
    onToast('Vault initialized — dual PIN configured')
  }

  /* ── Setup: action selection step ── */
  if (setup === 'action') {
    const opts = [
      { v: 1, ico: Eye, t: 'Decoy Only', d: 'Show fake environment, keep vault intact', danger: false },
      { v: 2, ico: Trash, t: 'Decoy + Purge Keys', d: 'Delete KeyStore keys, then show decoy', danger: false },
      { v: 3, ico: Warning, t: 'Hard Wipe Device', d: 'Factory reset via Device Admin', danger: true },
    ]
    return (
      <div className="lock">
        <div className="glow-a" /><div className="glow-b" />
        <div className="setup-card">
          <div className="stepno">3</div>
          <div>
            <div className="t1">Choose duress response</div>
            <div className="t2">What happens when the duress PIN is entered</div>
          </div>
        </div>
        <div className="action-list">
          {opts.map((o) => {
            const Icon = o.ico
            const sel = pendingAction === o.v
            return (
              <button key={o.v} className={`action-opt ${sel ? 'sel' : ''} ${o.danger ? 'danger' : ''}`} onClick={() => setPendingAction(o.v)}>
                <span className="ico"><Icon size={16} /></span>
                <span className="txt">
                  <div className="t1">{o.t}</div>
                  <div className="t2">{o.d}</div>
                </span>
                {sel && <CheckCircle size={17} style={{ color: o.danger ? 'var(--red)' : 'var(--green)' }} />}
              </button>
            )
          })}
        </div>
        <button className="btn-primary" onClick={finishSetup}>INITIALIZE SECURE VAULT</button>
        <button className="btn-ghost" onClick={() => { setSetup('duress'); setPendingDuress(''); setPin('') }}>← Back</button>
      </div>
    )
  }

  const activeSetup = setup === 'master' || setup === 'duress'

  return (
    <div className="lock">
      <div className="glow-a" />
      <div className="glow-b" />

      {mockMode && !activeSetup && (
        <div className="mock-banner" onClick={onConfig}>
          <Science size={13} />
          <span>MOCK TESTING MODE — NO REAL DATA LOSS</span>
          <span className="spacer" />
          <span className="cfg">CONFIG</span>
        </div>
      )}

      <div className="shield-wrap">
        <div className="shield-inner">
          <Shield size={30} style={{ color: 'var(--green)' }} sw={1.6} />
        </div>
      </div>

      <h2>CANARY</h2>
      <div className="sub">DURESS LOCK</div>

      <div className="state-chip">
        <span className="live-dot" />
        {lockout > 0 ? `LOCKED OUT · ${lockout}s` : 'SECURE VAULT LOCKED'}
      </div>

      {activeSetup ? (
        <>
          <div className="setup-card">
            <div className="stepno">{setup === 'master' ? '1' : '2'}</div>
            <div>
              <div className="t1">{setup === 'master' ? 'Set Master PIN — real vault' : 'Set Duress PIN — decoy trigger'}</div>
              <div className="t2">
                {setup === 'master' ? 'Unlocks your encrypted vault' : 'Silently triggers purge + decoy'}
              </div>
            </div>
          </div>

          <div className={`pin-dots ${error ? 'shake' : ''}`} style={{ marginTop: 26 }}>
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className={`pin-dot ${i < pin.length ? 'filled' : ''} ${i === pin.length ? 'active' : ''} ${error && i < pin.length ? 'error' : ''}`} />
            ))}
          </div>
          <div className="lock-msg">{message || <span className="faint">Enter 6 digits — tap to continue</span>}</div>
        </>
      ) : (
        <>
          <div className={`pin-dots ${error ? 'shake' : ''}`}>
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className={`pin-dot ${i < pin.length ? 'filled' : ''} ${i === pin.length ? 'active' : ''} ${error && i < pin.length ? 'error' : ''}`} />
            ))}
          </div>
          <div className="lock-msg">
            {busy ? <span className="faint">Verifying…</span>
              : message || (fails > 0 ? <span className="faint">Failed attempts: {fails}/5</span> : <span className="faint">Enter PIN to unlock</span>)}
          </div>
        </>
      )}

      <div className="keypad">
        {KEYPAD.map(([k, alpha]) => {
          if (k === 'clear') return (
            <button key="c" className="key action" onClick={() => press('clear')}><span className="num">CLEAR</span></button>
          )
          if (k === 'back') return (
            <button key="b" className="key action" onClick={() => press('back')}><span className="num">⌫</span></button>
          )
          return (
            <button key={k} className="key" onClick={() => press(k)}>
              <span className="num">{k}</span>
              <span className="alpha">{alpha}</span>
            </button>
          )
        })}
      </div>

      <div className="foot">
        <div className="line"><i /><span>CANARY DURESS LOCK v1.0</span><i /></div>
        <div className="line2">Hardware-Backed · StrongBox · TEE Isolated</div>
      </div>
    </div>
  )
}
