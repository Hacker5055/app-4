const base = ({ size = 18, sw = 1.8, ...rest }) => ({
  width: size,
  height: size,
  viewBox: '0 0 24 24',
  fill: 'none',
  stroke: 'currentColor',
  strokeWidth: sw,
  strokeLinecap: 'round',
  strokeLinejoin: 'round',
  ...rest,
})

export const Shield = (p) => (
  <svg {...base(p)}><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /></svg>
)
export const ShieldCheck = (p) => (
  <svg {...base(p)}><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" /><path d="m9 12 2 2 4-4" /></svg>
)
export const Lock = (p) => (
  <svg {...base(p)}><rect x="3" y="11" width="18" height="11" rx="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" /></svg>
)
export const Unlock = (p) => (
  <svg {...base(p)}><rect x="3" y="11" width="18" height="11" rx="2" /><path d="M7 11V7a5 5 0 0 1 9.9-1" /></svg>
)
export const Fingerprint = (p) => (
  <svg {...base(p)}>
    <path d="M12 10a2 2 0 0 0-2 2c0 1.02-.1 2.51-.26 4" />
    <path d="M14 13.12c0 2.38 0 6.38-1 8.88" /><path d="M17.29 21.02c.12-.6.43-2.3.5-3.02" />
    <path d="M2 12a10 10 0 0 1 18-6" /><path d="M2 16h.01" /><path d="M21.8 16c.2-2 .131-5.354 0-6" />
    <path d="M5 19.5C5.5 18 6 15 6 12a6 6 0 0 1 .34-2" /><path d="M8.65 22c.21-.66.45-1.32.57-2" />
    <path d="M9 6.8a6 6 0 0 1 9 5.2v2" />
  </svg>
)
export const Eye = (p) => (
  <svg {...base(p)}><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7z" /><circle cx="12" cy="12" r="3" /></svg>
)
export const Trash = (p) => (
  <svg {...base(p)}><path d="M3 6h18" /><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6" /><path d="M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" /><path d="M10 11v6" /><path d="M14 11v6" /></svg>
)
export const Warning = (p) => (
  <svg {...base(p)}><path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" /><path d="M12 9v4" /><path d="M12 17h.01" /></svg>
)
export const Calculator = (p) => (
  <svg {...base(p)}><rect x="4" y="2" width="16" height="20" rx="2" /><path d="M8 6h8" /><path d="M8 10h.01" /><path d="M12 10h.01" /><path d="M16 10h.01" /><path d="M8 14h.01" /><path d="M12 14h.01" /><path d="M16 14h.01" /><path d="M8 18h.01" /><path d="M12 18h.01" /><path d="M16 18h.01" /></svg>
)
export const Note = (p) => (
  <svg {...base(p)}><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" /><path d="M14 2v6h6" /><path d="M8 13h8" /><path d="M8 17h5" /></svg>
)
export const Image = (p) => (
  <svg {...base(p)}><rect x="3" y="3" width="18" height="18" rx="2" /><circle cx="8.5" cy="8.5" r="1.5" /><path d="m21 15-5-5L5 21" /></svg>
)
export const ChevronRight = (p) => (<svg {...base(p)}><path d="m9 18 6-6-6-6" /></svg>)
export const ChevronDown = (p) => (<svg {...base(p)}><path d="m6 9 6 6 6-6" /></svg>)
export const Plus = (p) => (<svg {...base(p)}><path d="M12 5v14" /><path d="M5 12h14" /></svg>)
export const Search = (p) => (<svg {...base(p)}><circle cx="11" cy="11" r="7" /><path d="m21 21-4.3-4.3" /></svg>)
export const More = (p) => (<svg {...base(p)}><circle cx="12" cy="12" r="1" /><circle cx="19" cy="12" r="1" /><circle cx="5" cy="12" r="1" /></svg>)
export const Tune = (p) => (<svg {...base(p)}><path d="M4 21v-7" /><path d="M4 10V3" /><path d="M12 21v-9" /><path d="M12 8V3" /><path d="M20 21v-5" /><path d="M20 12V3" /><path d="M1 14h6" /><path d="M9 8h6" /><path d="M17 16h6" /></svg>)
export const Key = (p) => (<svg {...base(p)}><circle cx="7.5" cy="15.5" r="4.5" /><path d="m21 2-9.6 9.6" /><path d="m15.5 7.5 3 3L22 7l-3-3" /></svg>)
export const Cpu = (p) => (<svg {...base(p)}><rect x="5" y="5" width="14" height="14" rx="2" /><rect x="9" y="9" width="6" height="6" /><path d="M9 2v3" /><path d="M15 2v3" /><path d="M9 19v3" /><path d="M15 19v3" /><path d="M2 9h3" /><path d="M2 15h3" /><path d="M19 9h3" /><path d="M19 15h3" /></svg>)
export const CheckCircle = (p) => (<svg {...base(p)}><circle cx="12" cy="12" r="10" /><path d="m9 12 2 2 4-4" /></svg>)
export const Check = (p) => (<svg {...base(p)}><path d="m20 6-11 11-5-5" /></svg>)
export const Close = (p) => (<svg {...base(p)}><path d="M18 6 6 18" /><path d="m6 6 12 12" /></svg>)
export const Info = (p) => (<svg {...base(p)}><circle cx="12" cy="12" r="10" /><path d="M12 16v-4" /><path d="M12 8h.01" /></svg>)
export const PhoneIn = (p) => (<svg {...base(p)}><path d="M16 2v6h6" /><path d="M21.5 2.5 16 8" /><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6A19.79 19.79 0 0 1 2.12 4.18 2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.12.96.36 1.9.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.9.34 1.85.58 2.81.7A2 2 0 0 1 22 16.92z" /></svg>)
export const PhoneOut = (p) => (<svg {...base(p)}><path d="M14 8V2h6" /><path d="M22 2 14 10" /><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6A19.79 19.79 0 0 1 2.12 4.18 2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.12.96.36 1.9.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.9.34 1.85.58 2.81.7A2 2 0 0 1 22 16.92z" /></svg>)
export const Home = (p) => (<svg {...base(p)}><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" /><path d="M9 22V12h6v10" /></svg>)
export const History = (p) => (<svg {...base(p)}><path d="M3 3v6h6" /><path d="M3.05 13A9 9 0 1 0 6 5.3L3 8" /><path d="M12 7v5l4 2" /></svg>)
export const Person = (p) => (<svg {...base(p)}><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" /></svg>)
export const Settings = (p) => (<svg {...base(p)}><circle cx="12" cy="12" r="3" /><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" /></svg>)
export const Grid = (p) => (<svg {...base(p)}><rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" /><rect x="14" y="14" width="7" height="7" /><rect x="3" y="14" width="7" height="7" /></svg>)
export const Lightbulb = (p) => (<svg {...base(p)}><path d="M9 18h6" /><path d="M10 22h4" /><path d="M12 2a7 7 0 0 0-4 12.7c.4.3.6.8.6 1.3H15.4c0-.5.2-1 .6-1.3A7 7 0 0 0 12 2z" /></svg>)
export const Bug = (p) => (<svg {...base(p)}><path d="m8 2 1.88 1.88" /><path d="M14.12 3.88 16 2" /><path d="M9 7.13v-1a3 3 0 1 1 6 0v1" /><path d="M12 20c-3.3 0-6-2.7-6-6v-3a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v3c0 3.3-2.7 6-6 6z" /><path d="M12 20v-9" /><path d="M6.53 9C4.6 8.8 3 7.1 3 5" /><path d="M6 13H2" /><path d="M3 21c0-2.1 1.7-3.9 3.8-4" /><path d="M20.97 5c0 2.1-1.6 3.8-3.5 4" /><path d="M22 13h-4" /><path d="M17.2 17c2.1.1 3.8 1.9 3.8 4" /></svg>)
export const Sliders = (p) => (<svg {...base(p)}><path d="M4 21v-7" /><path d="M4 10V3" /><path d="M12 21v-9" /><path d="M12 8V3" /><path d="M20 21v-5" /><path d="M20 12V3" /><path d="M1 14h6" /><path d="M9 8h6" /><path d="M17 16h6" /></svg>)
export const Admin = (p) => (<svg {...base(p)}><path d="M12 2 3 7v5c0 5 3.8 9.4 9 10 5.2-.6 9-5 9-10V7z" /><circle cx="12" cy="11" r="2" /><path d="M12 13v4" /></svg>)
export const FileText = (p) => (<svg {...base(p)}><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" /><path d="M14 2v6h6" /><path d="M9 15h6" /></svg>)
export const Folder = (p) => (<svg {...base(p)}><path d="M4 4h5l2 3h9a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1z" /></svg>)
export const VpnKey = (p) => (<svg {...base(p)}><circle cx="7.5" cy="15.5" r="4.5" /><path d="m21 2-9.6 9.6" /><path d="m15.5 7.5 3 3L22 7l-3-3" /></svg>)
export const Camera = (p) => (<svg {...base(p)}><path d="M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3z" /><circle cx="12" cy="13" r="3" /></svg>)
export const Memory = (p) => (<svg {...base(p)}><rect x="4" y="6" width="16" height="12" rx="2" /><path d="M8 6V4" /><path d="M16 6V4" /><path d="M8 20v-2" /><path d="M16 20v-2" /><path d="M2 10h2" /><path d="M2 14h2" /><path d="M20 10h2" /><path d="M20 14h2" /></svg>)
export const Verified = (p) => (<svg {...base(p)}><path d="m9 12 2 2 4-4" /><path d="M12 2 4 5v7c0 5 3.4 9.5 8 10 4.6-.5 8-5 8-10V5z" /></svg>)
export const ArrowRight = (p) => (<svg {...base(p)}><path d="M5 12h14" /><path d="m12 5 7 7-7 7" /></svg>)
export const Backspace = (p) => (<svg {...base(p)}><path d="M21 4H8l-7 8 7 8h13a2 2 0 0 0 2-2V6a2 2 0 0 0-2-2z" /><path d="m18 9-6 6" /><path d="m12 9 6 6" /></svg>)
export const Science = (p) => (<svg {...base(p)}><path d="M9 3h6" /><path d="M10 3v6l-5 9a2 2 0 0 0 1.7 3h10.6a2 2 0 0 0 1.7-3l-5-9V3" /><path d="M7 15h10" /></svg>)
export const Sparkle = (p) => (<svg {...base(p)}><path d="m12 3 2 5 5 2-5 2-2 5-2-5-5-2 5-2z" /></svg>)
export const Wifi = (p) => (<svg {...base(p)}><path d="M5 12.5a10 10 0 0 1 14 0" /><path d="M8.5 16a5 5 0 0 1 7 0" /><path d="M12 19.5h.01" /></svg>)
export const Signal = ({size = 16}) => (
  <svg width={size} height={size} viewBox="0 0 16 16" fill="currentColor">
    <rect x="1" y="10" width="2.5" height="4" rx="0.8" />
    <rect x="5" y="7.5" width="2.5" height="6.5" rx="0.8" />
    <rect x="9" y="5" width="2.5" height="9" rx="0.8" />
    <rect x="13" y="2" width="2.5" height="12" rx="0.8" opacity="0.45" />
  </svg>
)
export const Battery = ({size = 22}) => (
  <svg width={size} height={size * 0.55} viewBox="0 0 24 13" fill="none">
    <rect x="0.6" y="0.6" width="20" height="11.8" rx="3" stroke="currentColor" strokeWidth="1.2" opacity="0.55" />
    <rect x="2.2" y="2.2" width="12.5" height="8.6" rx="1.9" fill="currentColor" />
    <path d="M22.4 4.3v4.4c1-.3 1.4-1 1.4-2.2s-.4-1.9-1.4-2.2z" fill="currentColor" opacity="0.55" />
  </svg>
)
export const Apple = ({size = 14}) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor">
    <path d="M16.4 12.7c0-2.6 2.1-3.8 2.2-3.9-1.2-1.8-3.1-2-3.7-2-1.6-.2-3.1.9-3.9.9-.8 0-2-.9-3.3-.9-1.7 0-3.3 1-4.2 2.5-1.8 3.1-.5 7.7 1.3 10.2.9 1.2 1.9 2.6 3.2 2.5 1.3-.05 1.8-.8 3.3-.8 1.5 0 2 .8 3.3.8 1.4 0 2.3-1.2 3.1-2.5.9-1.4 1.3-2.7 1.3-2.8-.1 0-2.6-1-2.6-4z" />
    <path d="M14.2 4.6c.7-.9 1.2-2.1 1-3.3-1.1.05-2.4.7-3.1 1.6-.7.8-1.3 2-1.1 3.2 1.2.1 2.5-.6 3.2-1.5z" />
  </svg>
)
