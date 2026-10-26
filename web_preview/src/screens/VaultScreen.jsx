import React, { useState } from 'react'
import {
  Shield, Lock, Sliders, Science, Verified, Cpu, Fingerprint, FileText, VpnKey,
  Image, Note, ChevronRight, Plus, Key, Camera,
} from '../Icons.jsx'

const ITEMS = [
  { t: 'Passport Scan.pdf', c: 'Documents', d: 'Encrypted · AES-256-GCM · StrongBox' },
  { t: 'Bank Credentials', c: 'Credentials', d: 'Hardware-backed · biometric required' },
  { t: 'Private Photos (12)', c: 'Photos', d: 'End-to-end encrypted · zero-knowledge' },
  { t: 'Legal Documents', c: 'Documents', d: 'KeyStore protected · no backup' },
  { t: 'Recovery Keys', c: 'Credentials', d: 'Master seed · never leaves device' },
  { t: 'Trip Notes', c: 'Notes', d: 'Encrypted draft · 3 entries' },
]

const catIcon = (c) => (c === 'Photos' ? Image : c === 'Documents' ? FileText : c === 'Credentials' ? VpnKey : Note)

function Stat({ icon: Icon, label, value, sub, color, bg }) {
  return (
    <div className="stat">
      <div className="head">
        <span className="b" style={{ background: bg, color }}>
          <Icon size={12} />
        </span>
        <span className="lbl">{label}</span>
      </div>
      <div className="val" style={{ color }}>{value}</div>
      <div className="sub">{sub}</div>
    </div>
  )
}

export default function VaultScreen({ onLock, onConfig, mockMode, duressAction, purgeCount }) {
  const [cat, setCat] = useState('All')
  const cats = ['All', 'Photos', 'Documents', 'Credentials', 'Notes']
  const shown = cat === 'All' ? ITEMS : ITEMS.filter((i) => i.c === cat)
  const actionLabel = duressAction === 1 ? 'DECOY ONLY' : duressAction === 3 ? 'HARD WIPE' : 'PURGE'

  return (
    <div className="vault">
      <div className="glow-r" />

      <div className="vault-head">
        <div className="logo"><Shield size={18} /></div>
        <div>
          <div className="t1">CANARY VAULT</div>
          <div className="t2">Hardware encrypted · StrongBox</div>
        </div>
        <div className="spacer" />
        <button className="icon-btn" onClick={onConfig} title="Duress configuration"><Sliders size={15} /></button>
        <button className="icon-btn danger" onClick={onLock} title="Lock vault"><Lock size={15} /></button>
      </div>

      {mockMode && (
        <div className="mock-strip">
          <Science size={13} />
          MOCK TESTING — PURGES ARE SIMULATED
          <span className="chip" onClick={onConfig}>SETTINGS</span>
        </div>
      )}

      <div className="stat-grid">
        <Stat icon={Verified} label="VAULT STATUS" value="ENCRYPTED" sub="AES-256-GCM · TEE" color="#10B981" bg="rgba(16,185,129,0.12)" />
        <Stat icon={Fingerprint} label="BIOMETRIC" value="HARDWARE" sub="StrongBox backed" color="#3B82F6" bg="rgba(59,130,246,0.12)" />
        <Stat
          icon={Shield} label="DURESS PIN" value={purgeCount > 0 ? 'FIRED' : 'ARMED'} sub={actionLabel}
          color={purgeCount > 0 ? '#EF4444' : '#F59E0B'}
          bg={purgeCount > 0 ? 'rgba(239,68,68,0.12)' : 'rgba(245,158,11,0.12)'}
        />
        <Stat icon={Cpu} label="ITEMS SECURED" value={String(ITEMS.length)} sub="Zero-knowledge" color="#10B981" bg="rgba(16,185,129,0.12)" />
      </div>

      <div className="chips">
        {cats.map((c) => (
          <button key={c} className={`chip-btn ${cat === c ? 'on' : ''}`} onClick={() => setCat(c)}>{c}</button>
        ))}
      </div>

      <div className="items">
        {shown.map((it) => {
          const Icon = catIcon(it.c)
          return (
            <div className="item" key={it.t}>
              <span className="thumb"><Icon size={18} /></span>
              <span className="meta">
                <div className="n">{it.t}</div>
                <div className="d">{it.d}</div>
                <div className="row">
                  <span className="cat">{it.c}</span>
                  <span className="enc"><Lock size={9} /> Encrypted</span>
                </div>
              </span>
              <span className="chev"><ChevronRight size={16} /></span>
            </div>
          )
        })}
      </div>

      <div className="panel-card">
        <div className="row1">
          <span className="b"><Lock size={14} /></span>
          <span className="t">End-to-end encryption</span>
          <span className="spacer" />
          <span className="live-pill"><i />ACTIVE</span>
        </div>
        <p>
          Vault contents are sealed with AES-256-GCM using a key held in Android StrongBox.
          Key material never leaves the Trusted Execution Environment — and is deleted on duress.
        </p>
        <div className="tag-row">
          <span className="tag-sm"><Cpu size={9} /> TEE isolated</span>
          <span className="tag-sm"><Verified size={9} /> StrongBox</span>
          <span className="tag-sm"><Key size={9} /> AES-256</span>
        </div>
      </div>

      <div className="section-label">QUICK ACTIONS</div>
      <div className="quick-row">
        <button className="quick"><Camera size={17} />Add photo</button>
        <button className="quick"><Note size={17} />Add note</button>
        <button className="quick"><Key size={17} />Add secret</button>
      </div>

      <div className="vault-foot">
        <div className="l" />
        <div className="a">PROTECTED BY CANARY DURESS LOCK</div>
        <div className="b">Duress PIN purges keys — no recovery path</div>
      </div>
    </div>
  )
}
