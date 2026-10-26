import React, { useState, useEffect, useRef } from 'react'
import './theme.css'
import LockScreen from './screens/LockScreen.jsx'
import VaultScreen from './screens/VaultScreen.jsx'
import DecoyScreen from './screens/DecoyScreen.jsx'
import ConfigModal from './screens/ConfigModal.jsx'
import MockLogDialog from './screens/MockLogDialog.jsx'
import { Signal, Battery, Wifi, Shield, Lock, Science, Cpu, Sliders } from './Icons.jsx'

const stamp = () => {
  const d = new Date()
  return d.toTimeString().slice(0, 8)
}

const DEFAULT_PINS = { master: '123456', duress: '654321' }

export default function App() {
  const [screen, setScreen] = useState('lock')       // lock | vault | decoy
  const [pins, setPins] = useState(DEFAULT_PINS)
  const [hasPins, setHasPins] = useState(true)
  const [mockMode, setMockMode] = useState(true)
  const [action, setAction] = useState(2)
  const [showConfig, setShowConfig] = useState(false)
  const [mockLog, setMockLog] = useState(null)
  const [toast, setToast] = useState(null)
  const [events, setEvents] = useState([
    { time: stamp(), text: 'Canary engine booted · TEE attestation OK', cls: 'ok' },
    { time: stamp(), text: 'StrongBox available · key alias loaded', cls: '' },
  ])
  const [purgeCount, setPurgeCount] = useState(0)
  const [setupKey, setSetupKey] = useState(0)
  const toastTimer = useRef(null)

  const log = (text, cls = '') => setEvents((e) => [{ time: stamp(), text, cls }, ...e].slice(0, 40))

  const showToast = (msg) => {
    setToast(msg)
    clearTimeout(toastTimer.current)
    toastTimer.current = setTimeout(() => setToast(null), 2600)
  }

  useEffect(() => () => clearTimeout(toastTimer.current), [])

  const unlockMaster = () => {
    log('PIN verified · master key unwrapped from KeyStore', 'ok')
    log('Vault mounted · AES-256-GCM session active', '')
    setScreen('vault')
  }

  const triggerDuress = async () => {
    const labels = {
      1: 'Decoy only — no destruct',
      2: 'Decoy + purge keys',
      3: 'Hard wipe via Device Admin',
    }
    log(`Duress PIN matched · action=${labels[action]}`, 'warn')

    if (mockMode) {
      // Build the simulated execution log, then let the user step into decoy
      setMockLog([
        { text: `[${stamp()}] DURESS TRIGGERED — action: ${labels[action]}`, cls: 'warn' },
        { text: `[${stamp()}] Mock testing mode: true`, cls: '' },
        { text: `[${stamp()}] [MOCK] keyStore.deleteEntry(canary_master_vault_key_v1)` },
        { text: `[${stamp()}] [MOCK] entry removed — AES-256 key destroyed in hardware`, cls: 'ok' },
        { text: `[${stamp()}] [MOCK] MemoryZeroizer.zeroizeAll() → Arrays.fill(0x00) ×3 passes`, cls: 'ok' },
        { text: `[${stamp()}] [MOCK] secure storage + Hive key table cleared`, cls: 'ok' },
        ...(action === 3
          ? [{ text: `[${stamp()}] [MOCK] devicePolicyManager.wipeData(0) — BLOCKED by mock`, cls: 'err' }]
          : []),
        { text: `[${stamp()}] MOCK SEQUENCE COMPLETE — nothing was deleted`, cls: 'warn' },
      ])
      log('Mock purge simulated · decoy staged', 'warn')
      return
    }

    // Real (demo) execution timeline — mirrored in the side console only
    log('keyStore.deleteEntry(ALIAS) → hardware key destroyed', 'err')
    log('MemoryZeroizer.zeroizeAll() → buffers wiped 0x00', 'err')
    if (action === 3) log('DevicePolicyManager.wipeData(0) dispatched', 'err')
    setPurgeCount((c) => c + 1)
    // Seamless hand-off: no dialog, no error, straight into the decoy surface
    setScreen('decoy')
  }

  const continueToDecoy = () => {
    setMockLog(null)
    log('Decoy surface mounted · zero vault traces', 'warn')
    setScreen('decoy')
  }

  const saveConfig = ({ action: a, mockMode: m }) => {
    setAction(a)
    setMockMode(m)
    log(`Config saved · action=${a} mock=${m}`, 'ok')
    showToast(m ? 'Saved — mock mode on, purges simulated' : 'Saved — real purge armed')
  }

  const startWizard = () => {
    setHasPins(false)
    setSetupKey((k) => k + 1)
    setScreen('lock')
    log('First-launch wizard opened · provisioning new dual PIN', '')
  }

  const resetDemo = () => {
    setPins(DEFAULT_PINS)
    setHasPins(true)
    setAction(2)
    setMockMode(true)
    setPurgeCount(0)
    setScreen('lock')
    log('Demo state reset · default PINs restored', '')
    showToast('Demo reset — master 123456 / duress 654321')
  }

  const setupDone = ({ master, duress, action: a }) => {
    setPins({ master, duress })
    setHasPins(true)
    setAction(a)
    log('First launch · dual PIN provisioned, key generated', 'ok')
  }

  const isDarkBar = screen !== 'decoy'

  return (
    <div className="stage">
      <div className="device">
        <div className="notch" />
        <div className="screen">
          <div className={`statusbar ${isDarkBar ? 'light' : 'dark'}`} style={{ background: isDarkBar ? 'transparent' : '#fff' }}>
            <span>{new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
            <span className="icons">
              <Signal size={13} />
              <Wifi size={13} sw={2} />
              <Battery size={20} />
            </span>
          </div>

          <div className="screen-body" style={{ background: screen === 'decoy' ? 'var(--decoy-bg)' : 'var(--obsidian)' }}>
            {screen === 'lock' && (
              <LockScreen
                key={setupKey}
                pins={pins}
                hasPins={hasPins}
                mockMode={mockMode}
                onConfig={() => setShowConfig(true)}
                onMaster={unlockMaster}
                onDuress={triggerDuress}
                onToast={showToast}
                setupDone={setupDone}
              />
            )}
            {screen === 'vault' && (
              <VaultScreen
                mockMode={mockMode}
                duressAction={action}
                purgeCount={purgeCount}
                onConfig={() => setShowConfig(true)}
                onLock={() => { setScreen('lock'); log('Vault unmounted · session keys dropped', '') }}
              />
            )}
            {screen === 'decoy' && (
              <DecoyScreen onExit={() => { setScreen('lock'); log('Decoy dismissed · back to lock gate', '') }} />
            )}
          </div>

          {showConfig && (
            <ConfigModal
              action={action}
              mockMode={mockMode}
              onSave={saveConfig}
              onClose={() => setShowConfig(false)}
              onToast={showToast}
            />
          )}

          {mockLog && <MockLogDialog lines={mockLog} onContinue={continueToDecoy} />}
          {toast && <div className="toast">{toast}</div>}
        </div>
      </div>

      {/* ── Side panel ── */}
      <aside className="info">
        <div className="brand">
          <img src="/icon.png" alt="Canary Duress Lock" />
          <span className="brand-meta">
            <span className="brand-title">CANARY</span>
            <span className="brand-sub">DU RESS LOCK · v1.0</span>
          </span>
        </div>
        <h1>Canary <span>Duress Lock</span></h1>
        <div className="ar">نظام التمويه وقفل الطوارئ</div>
        <p className="lede">
          Anti-coercion vault for Android. Two PINs, one gate: your master code opens the real
          AES-256 vault, your duress code silently destroys the KeyStore key and hands the
          inspector a working calculator app instead.
        </p>

        <div className="info-block">
          <h3>Try it</h3>
          <div className="pin-row">
            <span className="dot" />
            <span className="pin-label">Master PIN → encrypted vault</span>
            <span className="pin-value">{pins.master}</span>
            <span className="tag">REAL</span>
          </div>
          <div className="pin-row">
            <span className="dot red" />
            <span className="pin-label">Duress PIN → decoy + purge</span>
            <span className="pin-value">{pins.duress}</span>
            <span className="tag red">COERCION</span>
          </div>
        </div>

        <div className="info-block">
          <h3>What to look for</h3>
          <ul className="hint-list">
            <li><span className="b">01</span><span>Both PINs open the app identically — no error, no hesitation, no hint that a second state exists.</span></li>
            <li><span className="b">02</span><span>Mock mode is on: the purge log shows every native call without deleting anything.</span></li>
            <li><span className="b">03</span><span>Turn mock mode off and the phone fades straight into the decoy — the console on the right records the hardware purge.</span></li>
            <li><span className="b">04</span><span>Exit the decoy by tapping the <b>Smart Tools</b> title five times.</span></li>
          </ul>
        </div>

        <div className="info-block">
          <h3>Live security console</h3>
          <div className="log-box" style={{ maxHeight: 150 }}>
            {events.map((e, i) => (
              <div key={i} className={e.cls}>
                <span style={{ opacity: 0.55 }}>{e.time}</span>  {e.text}
              </div>
            ))}
          </div>
        </div>

        <div className="badge-row">
          <span className="mini-badge"><Shield size={11} /> StrongBox / TEE</span>
          <span className="mini-badge"><Lock size={11} /> AES-256-GCM</span>
          <span className="mini-badge"><Cpu size={11} /> ARM64 release</span>
          <span className="mini-badge"><Science size={11} /> Mock testing</span>
          <button className="mini-badge" onClick={resetDemo} style={{ cursor: 'pointer' }}>
            <Sliders size={11} /> Reset demo
          </button>
          <button className="mini-badge" onClick={startWizard} style={{ cursor: 'pointer' }}>
            <Shield size={11} /> Setup wizard
          </button>
        </div>
      </aside>
    </div>
  )
}
