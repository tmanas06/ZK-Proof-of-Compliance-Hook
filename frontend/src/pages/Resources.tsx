const resources = [
  {
    title: 'Quick Start',
    subtitle: 'Boot your local Brevis + Uniswap stack in minutes.',
    link: '/QUICK_START.md'
  },
  {
    title: 'Architecture Deep Dive',
    subtitle: 'Understand hooks, EigenLayer AVS, and Fhenix flows.',
    link: '/docs/ARCHITECTURE.md'
  },
  {
    title: 'Frontend Styling Guide',
    subtitle: 'Customize themes & components safely.',
    link: '/docs/FRONTEND_SETUP.md'
  }
]

function ResourcesPage() {
  return (
    <div className="page resources-page">
      <section className="card glass">
        <h2>Knowledge Hub</h2>
        <p>
          Everything you need to operate a compliant Uniswap v4 experience. Browse deployment runbooks, environment tips,
          and integration patterns.
        </p>
      </section>

      <section className="resources-grid">
        {resources.map(res => (
          <article key={res.title} className="resource-card">
            <div>
              <h3>{res.title}</h3>
              <p>{res.subtitle}</p>
            </div>
            <a href={res.link} target="_blank" rel="noreferrer">
              View guide →
            </a>
          </article>
        ))}
      </section>
    </div>
  )
}

export default ResourcesPage

