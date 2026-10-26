import React, { useState } from 'react'
import {
  Calculator, Note, Image, Search, More, Tune, Plus, Lightbulb, Close, Grid,
  Home, History, Person, Settings, PhoneIn, PhoneOut, Info,
} from '../Icons.jsx'

const PHOTOS = [
  { t: 'Sunset at Nile', d: 'Oct 20, 2024', bg: '#FEF3C7', ico: '☀' },
  { t: 'Family Dinner', d: 'Oct 18, 2024', bg: '#D1FAE5', ico: '👨‍👩‍👧' },
  { t: 'Cats in Garden', d: 'Oct 15, 2024', bg: '#DBEAFE', ico: '🐈' },
  { t: 'Beach Day', d: 'Oct 12, 2024', bg: '#FCE7F3', ico: '🏖' },
  { t: 'Birthday Cake', d: 'Oct 08, 2024', bg: '#E0E7FF', ico: '🎂' },
  { t: 'Graduation', d: 'Oct 05, 2024', bg: '#FED7AA', ico: '🎓' },
  { t: 'IMG_1042.jpg', d: 'Oct 03, 2024', bg: '#E9D5FF', ico: '🌿' },
  { t: 'IMG_1039.jpg', d: 'Oct 02, 2024', bg: '#CFFAFE', ico: '🏙' },
  { t: 'IMG_1031.jpg', d: 'Sep 29, 2024', bg: '#FEE2E2', ico: '🎵' },
]

const CALLS = [
  { n: 'Mom', t: 'Today 09:12', dur: '2:34', out: true },
  { n: 'Ahmed — Work', t: 'Yesterday 16:45', dur: '5:12', out: false },
  { n: '+20 100 123 4567', t: 'Yesterday 11:20', dur: '', out: false, missed: true },
  { n: 'Sarah', t: 'Oct 24 14:30', dur: '1:05', out: true },
]

function Calc() {
  const [display, setDisplay] = useState('0')
  const [history, setHistory] = useState('')
  const [first, setFirst] = useState(null)
  const [op, setOp] = useState(null)
  const [awaiting, setAwaiting] = useState(false)
  const [past, setPast] = useState([])

  const digit = (d) => {
    if (display === '0' || awaiting) {
      setDisplay(d); setAwaiting(false)
    } else if (display.length < 12) {
      setDisplay(display + d)
    }
  }
  const dot = () => {
    if (awaiting) { setDisplay('0.'); setAwaiting(false); return }
    if (!display.includes('.')) setDisplay(display + '.')
  }
  const chooseOp = (o) => {
    setFirst(parseFloat(display)); setOp(o); setHistory(`${display} ${o}`); setAwaiting(true)
  }
  const equals = () => {
    if (first == null || !op) return
    const second = parseFloat(display)
    let r = 0
    if (op === '+') r = first + second
    if (op === '−') r = first - second
    if (op === '×') r = first * second
    if (op === '÷') r = second === 0 ? 0 : first / second
    const out = Number.isInteger(r) ? String(r) : String(Math.round(r * 1e6) / 1e6)
    setPast([`${history} ${display} = ${out}`, ...past].slice(0, 3))
    setDisplay(out); setHistory(''); setFirst(null); setOp(null); setAwaiting(false)
  }

  const keys = [
    { k: 'AC', cls: 'top', f: () => { setDisplay('0'); setHistory(''); setFirst(null); setOp(null) } },
    { k: '±', cls: 'top', f: () => display !== '0' && setDisplay(display.startsWith('-') ? display.slice(1) : '-' + display) },
    { k: '%', cls: 'top', f: () => setDisplay(String(parseFloat(display) / 100)) },
    { k: '÷', cls: 'op', f: () => chooseOp('÷') },
    { k: '7', f: () => digit('7') }, { k: '8', f: () => digit('8') }, { k: '9', f: () => digit('9') },
    { k: '×', cls: 'op', f: () => chooseOp('×') },
    { k: '4', f: () => digit('4') }, { k: '5', f: () => digit('5') }, { k: '6', f: () => digit('6') },
    { k: '−', cls: 'op', f: () => chooseOp('−') },
    { k: '1', f: () => digit('1') }, { k: '2', f: () => digit('2') }, { k: '3', f: () => digit('3') },
    { k: '+', cls: 'op', f: () => chooseOp('+') },
    { k: '0', f: () => digit('0') }, { k: '.', f: dot },
    { k: '⌫', f: () => setDisplay(display.length > 1 ? display.slice(0, -1) : '0') },
    { k: '=', cls: 'eq', f: equals },
  ]

  return (
    <>
      <div className="calc-display">
        <div className="hist">{history}</div>
        <div className="val">{display}</div>
        {past.length > 0 && (
          <div className="calc-history">
            {past.map((p, i) => <div key={i}>{p}</div>)}
          </div>
        )}
      </div>
      <div className="calc-grid">
        {keys.map((key, i) => (
          <button key={i} className={`calc-key ${key.cls || ''}`} onClick={key.f}>{key.k}</button>
        ))}
      </div>
    </>
  )
}

const NOTE_COLORS = ['#6366F1', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6']
const NOTE_DATA = [
  { t: 'Grocery List', p: 'Milk, bread, eggs, tomatoes, basil', d: 'Oct 24' },
  { t: 'Meeting Notes', p: 'Discuss Q4 roadmap with the team', d: 'Oct 22' },
  { t: 'Recipe — Koshari', p: 'Rice, lentils, pasta, tomato sauce', d: 'Oct 20' },
  { t: 'Workout Plan', p: 'Mon: chest · Tue: back · Wed: legs', d: 'Oct 18' },
]

function Notes() {
  const [notes, setNotes] = useState(NOTE_DATA)
  return (
    <>
      <div className="note-search">
        <Search size={15} />
        Search notes…
        <span className="spacer" />
        <span className="tune"><Tune size={12} /></span>
      </div>
      {notes.map((n, i) => (
        <div className="note-card" key={`${n.t}-${i}`}>
          <span className="b" style={{ background: `${NOTE_COLORS[i % 5]}1F`, color: NOTE_COLORS[i % 5] }}>
            <Note size={16} />
          </span>
          <span className="meta">
            <div className="t1">{n.t}</div>
            <div className="t2">{n.p}</div>
          </span>
          <span className="right">
            {n.d}
            <More size={14} />
          </span>
        </div>
      ))}
      <button className="note-add" onClick={() => setNotes([{ t: 'New note', p: 'Tap to edit this note…', d: 'Today' }, ...notes])}>
        <Plus size={15} /> New note
      </button>
    </>
  )
}

function Gallery() {
  return (
    <>
      <div className="gallery-filters">
        {['All photos', 'Camera', 'Screenshots', 'Downloads', 'Favorites'].map((f, i) => (
          <span key={f} className={`gfilter ${i === 0 ? 'on' : ''}`}>{f}</span>
        ))}
      </div>
      <div className="gallery-stats">
        1,248 photos · 12 videos
        <span className="spacer" />
        <span className="grid-view"><Grid size={11} /> Grid</span>
      </div>
      <div className="photo-grid">
        {PHOTOS.map((p) => (
          <div className="photo" key={p.t} style={{ background: p.bg }}>
            <span style={{ fontSize: 17 }}>{p.ico}</span>
            <span className="t">{p.t}</span>
            <span className="d">{p.d}</span>
          </div>
        ))}
      </div>
      <div className="calls">
        <div className="head">
          <span className="b"><PhoneIn size={12} /></span>
          <span className="t">Recent calls</span>
          <span className="spacer" />
          <span className="all">View all</span>
        </div>
        {CALLS.map((c) => (
          <div className="call-row" key={c.n}>
            <span className="av" style={{ color: c.missed ? '#EF4444' : '#10B981' }}>
              {c.out ? <PhoneOut size={13} /> : <PhoneIn size={13} />}
            </span>
            <span>
              <div className="n">{c.n}</div>
              <div className="t">{c.t}</div>
            </span>
            <span className="dur">{c.dur}</span>
          </div>
        ))}
      </div>
    </>
  )
}

export default function DecoyScreen({ onExit }) {
  const [tab, setTab] = useState(0)
  const [taps, setTaps] = useState(0)
  const [askExit, setAskExit] = useState(false)
  const [banner, setBanner] = useState(true)

  const secretTap = () => {
    const n = taps + 1
    setTaps(n)
    if (n >= 5) { setTaps(0); setAskExit(true) }
    setTimeout(() => setTaps(0), 2500)
  }

  const tabs = [
    { ico: Calculator, label: 'Calculator' },
    { ico: Note, label: 'Notes' },
    { ico: Image, label: 'Gallery' },
  ]

  return (
    <div className="decoy">
      <div className="decoy-top">
        <div className="decoy-title">
          <span className="b"><Calculator size={16} /></span>
          <span onClick={secretTap} style={{ cursor: 'default' }}>
            <div className="t1">Smart Tools</div>
            <div className="t2">Calculator · Notes · Gallery</div>
          </span>
          <span className="spacer" />
          <span className="icon"><Search size={16} /></span>
          <span className="icon" style={{ marginLeft: 10 }}><More size={16} /></span>
        </div>
        <div className="decoy-tabs">
          {tabs.map((t, i) => {
            const Icon = t.ico
            return (
              <button key={t.label} className={`decoy-tab ${tab === i ? 'on' : ''}`} onClick={() => setTab(i)}>
                <Icon size={17} />
                {t.label}
              </button>
            )
          })}
        </div>
      </div>

      <div className="decoy-body">
        {banner && (
          <div className="decoy-banner">
            <span className="b"><Lightbulb size={13} /></span>
            <span>
              <div className="t1">Tip: swipe between tabs</div>
              <div className="t2">Your tools are ready to use</div>
            </span>
            <span className="x" onClick={() => setBanner(false)}><Close size={14} /></span>
          </div>
        )}
        {tab === 0 && <Calc />}
        {tab === 1 && <Notes />}
        {tab === 2 && <Gallery />}
      </div>

      <div className="decoy-nav">
        <span className="n on"><Home size={17} />Home</span>
        <span className="n"><History size={17} />History</span>
        <span className="n"><Person size={17} />Profile</span>
        <span className="n"><Settings size={17} />Settings</span>
      </div>

      {askExit && (
        <div className="overlay center" onClick={() => setAskExit(false)}>
          <div className="dialog" style={{ background: '#fff', border: '1px solid #E2E8F0' }} onClick={(e) => e.stopPropagation()}>
            <div style={{ fontSize: 14, fontWeight: 700, color: '#1E293B', marginBottom: 6 }}>Exit decoy?</div>
            <div style={{ fontSize: 12, color: '#94A3B8', lineHeight: 1.5 }}>
              Return to the lock screen. Your PIN will be required again.
            </div>
            <div className="actions">
              <button className="btn-sm text" style={{ color: '#94A3B8' }} onClick={() => setAskExit(false)}>Cancel</button>
              <button className="btn-sm solid" style={{ background: '#6366F1', color: '#fff' }} onClick={() => { setAskExit(false); setTab(0); onExit() }}>Exit</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
