import React, { useState } from 'react'
import { Shield, Eye, Trash, Warning, Science, Admin, Fingerprint, CheckCircle, Close, Key } from '../Icons.jsx'

const OPTIONS = [
  { v: 1, ico: Eye, t: 'Decoy Only', d: 'Show fake environment. Vault data stays intact but hidden.', risk: 'LOW RISK', color: '#3B82F6', bg: 'rgba(59,130,246,0.12)' },
  { v: 2, ico: Trash, t: 'Decoy + Purge keys', d: 'Delete KeyStore keys, then show decoy. Unrecoverable.', risk: 'RECOMMENDED', color: '#10B981', bg: 'rgba(16,185,129,0.12)' },
  { v: 3, ico: Warning, t: 'Hard wipe device', d: 'Factory reset via Device Admin. Requires admin rights.', risk: 'DESTRUCTIVE', color: '#EF4444', bg: 'rgba(239,68,68,0.12)' },
]

function Toggle({ icon: Icon, title, sub, value, color, bg, onToggle, amber }) {
  return (
    <div className="toggle-row">
      <span className="b" style={{ background: value ? bg : 'rgba(148,163,184,0.1)', color: value ? color : '#64748B' }}>
        <Icon size={13} />
      </span>
      <span className="meta">
        <div className="t1">{title}</div>
        <div className="t2" style={{ color: value ? color : 'var(--muted)' }}>{sub}</div>
      </span>
      <button className={`switch ${value ? 'on' : ''} ${amber ? 'amber' : ''}`} onClick={onToggle}>
        <i />
      </button>
    </div>
  )
}

export default function ConfigModal({ action, mockMode, onSave, onClose, onToast }) {
  const [sel, setSel] = useState(action)
  const [mock, setMock] = useState(mockMode)
  const [admin, setAdmin] = useState(false)
  const [bio, setBio] = useState(false)
  const [showPins, setShowPins] = useState(false)

  return (
    <div className="overlay" onClick={onClose}>
      <div className="sheet" onClick={(e) => e.stopPropagation()}>
        <div className="grabber" />
        <div className="sheet-head">
          <span className="b"><Shield size={18} /></span>
          <span>
            <div className="t1">Duress configuration</div>
            <div className="t2">Configure emergency response actions</div>
          </span>
          <button className="x" onClick={onClose}><Close size={14} /></button>
        </div>

        <div className="field-label">DURESS RESPONSE ACTION</div>
        {OPTIONS.map((o) => {
          const Icon = o.ico
          const on = sel === o.v
          return (
            <button
              key={o.v}
              className={`action-opt ${on ? 'sel' : ''} ${o.v === 3 ? 'danger' : ''}`}
              onClick={() => setSel(o.v)}
              style={{
                width: '100%',
                marginBottom: 8,
                ...(on ? { borderColor: o.color, background: o.bg } : {}),
              }}
            >
              <span className="ico"><Icon size={15} /></span>
              <span className="txt">
                <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
                  <span className="t1">{o.t}</span>
                  <span style={{ fontSize: 8, fontWeight: 800, letterSpacing: 0.5, padding: '2px 5px', borderRadius: 4, background: o.bg, color: o.color }}>{o.risk}</span>
                </div>
                <div className="t2">{o.d}</div>
              </span>
              {on && <CheckCircle size={17} style={{ color: o.color }} />}
            </button>
          )
        })}

        <div style={{ marginTop: 18 }}>
          <div className="field-label">SECURITY OPTIONS</div>
          <Toggle
            icon={Science} title="Mock testing mode"
            sub={mock ? 'ON — purges simulated, nothing deleted' : 'OFF — real purge executes'}
            value={mock} color="#F59E0B" bg="rgba(245,158,11,0.12)" amber onToggle={() => setMock(!mock)}
          />
          <Toggle
            icon={Admin} title="Device admin (hard wipe)"
            sub={admin ? 'Active — wipe authorized' : 'Inactive — tap to request'}
            value={admin} color="#10B981" bg="rgba(16,185,129,0.12)"
            onToggle={() => { setAdmin(!admin); if (!admin) onToast('Device Admin request — approve in system settings') }}
          />
          <Toggle
            icon={Fingerprint} title="Biometric unlock"
            sub="Fingerprint / face for vault access"
            value={bio} color="#10B981" bg="rgba(16,185,129,0.12)" onToggle={() => setBio(!bio)}
          />
        </div>

        <div style={{ marginTop: 16 }}>
          <button
            className="action-opt"
            style={{ width: '100%' }}
            onClick={() => setShowPins(!showPins)}
          >
            <span className="ico" style={{ background: 'rgba(16,185,129,0.12)', color: 'var(--green)' }}><Key size={15} /></span>
            <span className="txt"><div className="t1">Change PINs</div><div className="t2">Master and duress codes</div></span>
            <span style={{ color: 'var(--muted)', fontSize: 16 }}>{showPins ? '−' : '+'}</span>
          </button>
          {showPins && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginTop: 8 }}>
              <input
                placeholder="New master PIN (6 digits)" maxLength={6} inputMode="numeric"
                style={{ padding: '11px 13px', borderRadius: 10, background: 'var(--panel)', border: '1px solid var(--border)', color: 'var(--text)', fontSize: 12, letterSpacing: 4, outline: 'none' }}
              />
              <input
                placeholder="New duress PIN (6 digits)" maxLength={6} inputMode="numeric"
                style={{ padding: '11px 13px', borderRadius: 10, background: 'var(--panel)', border: '1px solid var(--border)', color: 'var(--text)', fontSize: 12, letterSpacing: 4, outline: 'none' }}
              />
            </div>
          )}
        </div>

        <div className="warn-box">
          <Warning size={15} />
          <span>
            <div className="t1">Irreversible action warning</div>
            <div className="t2">
              Purge operations permanently delete encryption keys from StrongBox. Without a backup,
              vault contents cannot be recovered.
            </div>
          </span>
        </div>

        <button
          className="btn-primary"
          style={{ width: '100%', marginTop: 16 }}
          onClick={() => { onSave({ action: sel, mockMode: mock }); onClose() }}
        >
          SAVE CONFIGURATION
        </button>
        <div style={{ textAlign: 'center', fontSize: 9, letterSpacing: 0.5, color: 'var(--ghost)', marginTop: 10 }}>
          TEE isolated · StrongBox backed
        </div>
      </div>
    </div>
  )
}
