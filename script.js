// Search tab switching
document.querySelectorAll('.stab').forEach(tab => {
  tab.addEventListener('click', () => {
    document.querySelectorAll('.stab').forEach(t => t.classList.remove('active'));
    tab.classList.add('active');

    const placeholders = {
      all: 'What are you looking for?',
      property: 'Apartment, villa, studio...',
      motors: 'Car make, model, year...',
      jobs: 'Job title, company, keyword...',
    };
    const input = document.querySelector('.search-field input');
    if (input) input.placeholder = placeholders[tab.dataset.tab] || placeholders.all;
  });
});

// Nav category active state
document.querySelectorAll('.nav-link').forEach(link => {
  link.addEventListener('click', e => {
    e.preventDefault();
    document.querySelectorAll('.nav-link').forEach(l => l.classList.remove('active'));
    link.classList.add('active');
  });
});

// Search button
document.querySelector('.search-btn').addEventListener('click', () => {
  const query = document.querySelector('.search-field input').value.trim();
  if (query) {
    // In a real app this would route to search results
    console.log('Searching for:', query);
  }
});

// Enter key in search
document.querySelector('.search-field input').addEventListener('keydown', e => {
  if (e.key === 'Enter') document.querySelector('.search-btn').click();
});

// Smooth fade-in on scroll
const observer = new IntersectionObserver(entries => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.style.opacity = '1';
      entry.target.style.transform = 'translateY(0)';
    }
  });
}, { threshold: 0.1 });

document.querySelectorAll('.listing-card, .cat-card, .job-card').forEach(el => {
  el.style.opacity = '0';
  el.style.transform = 'translateY(16px)';
  el.style.transition = 'opacity .4s ease, transform .4s ease';
  observer.observe(el);
});
