import React from 'react'
import { Bug } from '../Icons.jsx'

export default function MockLogDialog({ lines, onContinue }) {
  return (
    <div className="overlay center">
      <div className="dialog">
        <div className="dh">
          <span className="b"><Bug size={16} /></span>
          <span className="t">Mock duress log</span>
        </div>
        <div className="log-box">
          {lines.map((l, i) => (
            <div key={i} className={l.cls || ''}>{l.text}</div>
          ))}
        </div>
        <div className="dn">
          No data was deleted. This is mock mode — the real sequence is identical but
          irreversibly deletes the StrongBox key.
        </div>
        <div className="actions">
          <button className="btn-sm solid" onClick={onContinue}>Enter decoy mode</button>
        </div>
      </div>
    </div>
  )
}
