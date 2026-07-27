const downloadUrl = "https://github.com/kkz6/ZoneBar/releases/latest";

const clocks = [
  { city: "San Francisco", code: "SFO", offset: "GMT−7", time: "09:41", active: true },
  { city: "London", code: "LON", offset: "GMT+1", time: "17:41", active: true },
  { city: "Bengaluru", code: "BLR", offset: "GMT+5:30", time: "22:11", active: false },
  { city: "Tokyo", code: "TKY", offset: "GMT+9", time: "01:41", active: false, day: "+1" },
];

const features = [
  {
    index: "01",
    title: "All your timezones, one click away",
    copy: "City time, GMT offset, day or night, and tomorrow/yesterday context in a compact native popover.",
    visual: "clocks",
  },
  {
    index: "02",
    title: "Find a meeting time without the math",
    copy: "Drag the timeline and every clock moves together. A green marker shows when working hours overlap.",
    visual: "scrub",
  },
  {
    index: "03",
    title: "Make the menu bar fit your workflow",
    copy: "Choose visible clocks, compact city labels, 12- or 24-hour time, date display, and separators.",
    visual: "menu",
  },
  {
    index: "04",
    title: "Native, offline, and private",
    copy: "Built in SwiftUI. No account, analytics, subscription, or network connection. Your clocks stay on your Mac.",
    visual: "private",
  },
];

function ClockPopover() {
  return (
    <div className="app-window">
      <div className="menu-preview">
        <span className="live-dot" />
        SFO 09:41 <i /> LON 17:41 <i /> BLR 22:11
      </div>
      <div className="popover-head">
        <span>Monday, 27 July</span>
        <button aria-label="Add a city">+</button>
      </div>
      <div className="clock-list">
        {clocks.map((clock) => (
          <div className="clock-row" key={clock.city}>
            <span className={`status-icon ${clock.active ? "day" : "night"}`}>
              {clock.active ? "✦" : "●"}
            </span>
            <span className="clock-place">
              <strong>{clock.city}</strong>
              <small>{clock.code} · {clock.offset}</small>
            </span>
            {clock.day && <span className="next-day">{clock.day}</span>}
            <time>{clock.time}</time>
          </div>
        ))}
      </div>
      <div className="timeline">
        <div className="timeline-labels"><span>−12h</span><strong>Now</strong><span>+12h</span></div>
        <div className="timeline-track"><i /><b /></div>
        <p><span /> Working hours overlap</p>
      </div>
      <div className="window-foot"><span>4 clocks</span><span>Settings&nbsp;&nbsp; Quit</span></div>
    </div>
  );
}

function FeatureVisual({ type }: { type: string }) {
  if (type === "clocks") {
    return (
      <div className="mini-clocks" aria-hidden="true">
        <div><span className="day-pip" /><strong>San Francisco</strong><time>09:41</time></div>
        <div><span className="day-pip" /><strong>London</strong><time>17:41</time></div>
        <div><span className="night-pip" /><strong>Tokyo</strong><time>01:41</time></div>
      </div>
    );
  }

  if (type === "scrub") {
    return (
      <div className="mini-scrub" aria-hidden="true">
        <div><span>−6h</span><strong>Now</strong><span>+6h</span></div>
        <section><i /><b /></section>
        <p><span /> 3 zones within working hours</p>
      </div>
    );
  }

  if (type === "menu") {
    return (
      <div className="mini-menu" aria-hidden="true">
        <span>SFO&nbsp; 09:41</span><i />
        <span>LON&nbsp; 17:41</span><i />
        <span>BLR&nbsp; 22:11</span>
      </div>
    );
  }

  return (
    <div className="mini-private" aria-hidden="true">
      <span className="privacy-ring"><i>✓</i></span>
      <div><strong>Your data stays local</strong><small>No account · No network · No tracking</small></div>
    </div>
  );
}

export default function Home() {
  return (
    <>
      <a className="skip-link" href="#content">Skip to content</a>
      <header className="site-nav shell">
        <a className="brand" href="#top" aria-label="ZoneBar home">
          <img src="/zonebar-icon.png" alt="" width="34" height="34" />
          <span>ZoneBar</span>
        </a>
        <nav aria-label="Main navigation">
          <a href="#features">Features</a>
          <a href="#install">Install</a>
          <a href="#faq">FAQ</a>
        </nav>
        <a className="nav-cta" href={downloadUrl}>Download <span>↓</span></a>
      </header>

      <main id="content">
        <section className="hero shell" id="top">
          <div className="hero-copy">
            <p className="eyebrow"><span /> Built for macOS</p>
            <h1>World clocks,<br />without the clutter.</h1>
            <p className="hero-lede">
              ZoneBar puts your team’s timezones in the menu bar and helps you
              find a good time to talk—without opening another browser tab.
            </p>
            <div className="hero-actions">
              <a className="button primary" href={downloadUrl}>
                <span className="download-mark">↓</span> Download for macOS
              </a>
              <a className="text-link" href="#features">Explore features <span>→</span></a>
            </div>
            <div className="hero-meta">
              <span><b>Free</b> and open source</span>
              <span><b>macOS 14+</b> Sonoma or later</span>
              <span><b>Universal</b> Apple silicon + Intel</span>
            </div>
          </div>

          <div className="product-stage" aria-label="ZoneBar app preview">
            <div className="stage-grid" />
            <ClockPopover />
            <span className="float-note note-one"><b>4</b> timezones</span>
            <span className="float-note note-two"><i /> overlap found</span>
          </div>
        </section>

        <section className="quick-proof">
          <div className="shell proof-grid">
            <div><strong>176+</strong><span>cities included</span></div>
            <div><strong>0</strong><span>accounts required</span></div>
            <div><strong>1 click</strong><span>to check every clock</span></div>
            <p>Fast, native, and designed to disappear into your workflow.</p>
          </div>
        </section>

        <section className="features-section shell" id="features">
          <header className="section-head">
            <p className="eyebrow"><span /> What it does</p>
            <h2>Less converting.<br />More coordinating.</h2>
            <p>Everything you need for global work, kept deliberately small.</p>
          </header>

          <div className="feature-grid">
            {features.map((feature) => (
              <article className={`feature-card feature-${feature.visual}`} key={feature.index}>
                <div className="feature-top">
                  <span>{feature.index}</span>
                  <FeatureVisual type={feature.visual} />
                </div>
                <h3>{feature.title}</h3>
                <p>{feature.copy}</p>
              </article>
            ))}
          </div>
        </section>

        <section className="install-section" id="install">
          <div className="install shell">
            <div className="install-copy">
              <p className="eyebrow"><span /> Quick install</p>
              <h2>On your Mac<br />in under a minute.</h2>
              <p>A familiar drag-to-Applications install. No installer wizard and no account setup.</p>
              <a className="button primary" href={downloadUrl}>Download ZoneBar <span>↓</span></a>
            </div>
            <ol className="install-steps">
              <li><span>01</span><div><strong>Download the DMG</strong><p>Get the latest signed and notarized release.</p></div></li>
              <li><span>02</span><div><strong>Move it to Applications</strong><p>Drag ZoneBar into the Applications shortcut.</p></div></li>
              <li><span>03</span><div><strong>Pick your cities</strong><p>ZoneBar appears in the menu bar and stays out of the way.</p></div></li>
            </ol>
          </div>
        </section>

        <section className="faq shell" id="faq">
          <header>
            <p className="eyebrow"><span /> FAQ</p>
            <h2>A few useful details.</h2>
          </header>
          <div className="faq-grid">
            <article><h3>Does ZoneBar collect data?</h3><p>No. It has no account, analytics, or network access. Your settings stay on your Mac.</p></article>
            <article><h3>Which Macs work?</h3><p>Any Apple silicon or Intel Mac running macOS 14 Sonoma or later.</p></article>
            <article><h3>Is the download safe?</h3><p>Public builds are signed with Developer ID and notarized by Apple before release.</p></article>
            <article><h3>Can it open at login?</h3><p>Yes. Turn on “Launch at login” in ZoneBar’s General settings.</p></article>
          </div>
        </section>

        <section className="final-cta shell">
          <div>
            <img src="/zonebar-icon.png" alt="" width="52" height="52" />
            <h2>Keep every timezone close.</h2>
            <p>Free, native, and ready for your menu bar.</p>
          </div>
          <a className="button light" href={downloadUrl}>Download for macOS <span>↓</span></a>
        </section>
      </main>

      <footer className="site-footer shell" id="privacy">
        <a className="brand" href="#top"><img src="/zonebar-icon.png" alt="" width="30" height="30" /><span>ZoneBar</span></a>
        <p>Private by design. ZoneBar collects no personal data.</p>
        <p>© 2026 GigCodes</p>
      </footer>
    </>
  );
}
