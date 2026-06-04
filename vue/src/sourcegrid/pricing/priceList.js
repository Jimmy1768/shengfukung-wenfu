export const priceList = {
  currencyNote:
    'Pricing is a planning guide. Public funnels may be free, platform operations may be monthly, and pilots may change after real client validation.',
  offerings: [
    {
      id: 'dojomate-free-funnel',
      category: 'network_marketplace',
      icon: 'D',
      readiness: 'ready',
      priceMode: 'free',
      priceLabel: 'Free',
      title: 'DojoMate',
      tagline: 'Free martial arts funnel',
      summary:
        'A free martial arts network product designed for adoption, community density, and routing serious users into Source Combatives.',
      included: [
        'Free club, coach, student, and community-facing surface.',
        'Low-friction onboarding for martial arts schools and users.',
        'Optional paid productivity tools only when schools need operational features.',
        'Distribution funnel into Source Combatives.',
        'Word mark currently registered in Singapore.'
      ],
      typicalClients: [
        'Martial arts schools, coaches, students, and community groups.',
        'Users who should not face payment friction before joining the network.'
      ],
      hoverNote:
        'DojoMate should not be priced as normal SaaS. The goal is scale and trust first.'
    },
    {
      id: 'source-combatives',
      category: 'network_marketplace',
      icon: 'C',
      readiness: 'ready',
      priceMode: 'service_fee',
      priceLabel: 'Service fee per subscriber',
      title: 'Source Combatives',
      tagline: 'Curriculum marketplace revenue',
      summary:
        'The paid martial arts curriculum platform monetized through a service fee per subscriber rather than charging the DojoMate funnel.',
      included: [
        'Online curriculum hosting and subscriber access.',
        'Creator/instructor publishing path.',
        'Revenue share or service fee on paid subscriptions.',
        'Connected user flow from DojoMate.',
        'Word mark currently registered in Singapore.'
      ],
      typicalClients: [
        'Curriculum creators, martial arts instructors, and serious students.',
        'Communities where free DojoMate adoption can convert into paid curriculum access.'
      ],
      hoverNote:
        'This is the monetization layer for the martial arts network, not a setup-fee product.'
    },
    {
      id: 'templemate-platform',
      category: 'platform_tenant',
      icon: 'T',
      readiness: 'pilot',
      priceMode: 'monthly_after_grace',
      monthlyTWD: 3000,
      title: 'TempleMate',
      tagline: 'Free public site, paid workflow',
      summary:
        'Temples can sign up for free, publish a public marketing/profile site, then pay monthly for registration and business workflows after a grace period.',
      included: [
        'Free temple profile and public marketing website.',
        'Temple details, service/pricing information, announcements, and public content.',
        'Monthly paid access for registration or business workflows.',
        'Grace period before billing enforcement.',
        'If delinquent, public website stays online but registration/business workflows freeze.'
      ],
      typicalClients: [
        'Taiwanese temples and religious/community organizations.',
        'Organizations where public visibility should remain live even if business workflows are paused.'
      ],
      hoverNote:
        'The public website is the funnel. The paid value is operational workflow access.'
    },
    {
      id: 'tenant-website-launch',
      category: 'platform_tenant',
      icon: 'W',
      readiness: 'ready',
      priceMode: 'setup_plus_monthly',
      setupUSD: 800,
      monthlyUSD: 80,
      setupTWD: 25000,
      monthlyTWD: 2500,
      title: 'Tenant Website Launch',
      tagline: 'Ready now',
      summary:
        'A hosted business website under the SourceGrid system, with a custom domain, branded pages, contact flow, and basic admin.',
      included: [
        'Custom-domain marketing website.',
        'Business profile, service pages, gallery/news sections, and contact form.',
        'Basic admin for content updates.',
        'Hosting, deployment, backups, and light monitoring.',
        'SourceGrid keeps the platform and infrastructure maintained.'
      ],
      typicalClients: [
        'Schools, gyms, local service businesses, and small hospitality operators.',
        'Clients that need a credible online presence without owning custom infrastructure.'
      ],
      hoverNote: 'This is the baseline platform onboarding offer.'
    },
    {
      id: 'hostel-hotel-bookings',
      category: 'vertical_pilot',
      icon: 'B',
      readiness: 'pilot',
      priceMode: 'pilot',
      setupUSD: 1500,
      monthlyUSD: 150,
      setupTWD: 47000,
      monthlyTWD: 4700,
      title: 'Hostel / Hotel Bookings',
      tagline: 'Pilot scope',
      summary:
        'Tenant website plus room, bed, or booking-management workflows for small hotels, hostels, and guesthouses.',
      included: [
        'Everything in Tenant Website Launch.',
        'Room or bed inventory model.',
        'Booking request or reservation workflow.',
        'Staff dashboard for reservations and guest status.',
        'Email or message-based confirmations where payment rails are not ready.',
        'Operational testing with the first client before broad resale.'
      ],
      typicalClients: [
        'Small hotels, hostels, surf hostels, and guesthouses.',
        'Businesses that need a simple owned booking surface before full OTA-style automation.'
      ],
      hoverNote:
        'Good near-term target, but must be treated as a pilot until booking edge cases are tested.'
    },
    {
      id: 'equipment-rentals',
      category: 'vertical_pilot',
      icon: 'R',
      readiness: 'pilot',
      priceMode: 'pilot',
      setupUSD: 1500,
      monthlyUSD: 150,
      setupTWD: 47000,
      monthlyTWD: 4700,
      title: 'Equipment Rentals',
      tagline: 'Pilot scope',
      summary:
        'Tenant website plus rental inventory, availability, customer requests, and staff workflow for small rental operators.',
      included: [
        'Everything in Tenant Website Launch.',
        'Equipment catalog and availability model.',
        'Rental request or reservation workflow.',
        'Staff dashboard for pickup, return, and status tracking.',
        'Optional deposit/payment integration when local rails are confirmed.',
        'Operational testing before broad resale.'
      ],
      typicalClients: [
        'Surfboard, scooter, bike, gear, and outdoor equipment rental operators.',
        'Hostel-adjacent businesses that need lightweight inventory control.'
      ],
      hoverNote:
        'Adjacent to hotel/hostel bookings, but has different inventory, deposit, and return-risk rules.'
    },
    {
      id: 'nursing-home-dependent-care',
      category: 'vertical_pilot',
      icon: 'N',
      readiness: 'pilot',
      priceMode: 'pilot',
      setupUSD: 2500,
      monthlyUSD: 250,
      setupTWD: 78000,
      monthlyTWD: 7800,
      title: 'Nursing Home / Dependent Care',
      tagline: 'Pilot scope',
      summary:
        'Tenant website plus dependent-account workflows for care facilities, family access, records, and operational coordination.',
      included: [
        'Everything in Tenant Website Launch.',
        'Dependent account and guardian/family relationship model.',
        'Facility-facing dashboard for resident/client workflows.',
        'Role and permission review for staff and family access.',
        'Careful data/privacy review before production use.',
        'Operational testing with the first facility before broad resale.'
      ],
      typicalClients: [
        'Nursing homes, elder-care facilities, dependent-care providers, and family service organizations.',
        'Clients where Golden Template dependent accounts can become a reusable platform primitive.'
      ],
      hoverNote:
        'Higher support and privacy risk than hotel/rental work, so it should not be priced too low.'
    },
    {
      id: 'managed-custom-module',
      category: 'platform_tenant',
      icon: 'M',
      readiness: 'case_by_case',
      priceMode: 'quote',
      priceLabel: 'Quoted after intake',
      title: 'Managed Custom Module',
      tagline: 'Case by case',
      summary:
        'A custom workflow module built on the SourceGrid tenant platform when the client need does not fit an existing vertical.',
      included: [
        'Scope intake and workflow mapping.',
        'Tenant-specific admin workflow.',
        'Data model and permissions review.',
        'Manual acceptance testing before launch.',
        'Maintenance path after the module becomes stable.'
      ],
      typicalClients: [
        'Clients with a clear operational workflow that can become a reusable vertical later.',
        'Niche operators where SourceGrid can learn once and reuse the pattern.'
      ],
      hoverNote:
        'Use this only when the work can strengthen the platform or open a niche, not for random custom builds.'
    }
  ],
  addons: [
    {
      id: 'dojomate-productivity-tools',
      readiness: 'pilot',
      priceMode: 'quote',
      priceLabel: 'Optional paid tools',
      category: 'network_marketplace'
    },
    {
      id: 'custom-domain',
      readiness: 'ready',
      priceMode: 'monthly',
      monthlyUSD: 10,
      monthlyTWD: 300
    },
    {
      id: 'payment-rail-integration',
      readiness: 'case_by_case',
      priceMode: 'quote',
      priceLabel: 'Quoted by country/payment rail'
    },
    {
      id: 'multi-language',
      readiness: 'ready',
      priceMode: 'setup',
      setupUSD: 300,
      setupTWD: 9500
    },
    {
      id: 'staff-training',
      readiness: 'ready',
      priceMode: 'setup',
      setupUSD: 250,
      setupTWD: 7800
    },
    {
      id: 'data-import',
      readiness: 'case_by_case',
      priceMode: 'quote',
      priceLabel: 'Quoted after file review'
    }
  ],
  maintenance: [
    {
      id: 'included-platform-care',
      readiness: 'ready',
      priceMode: 'included',
      priceLabel: 'Included with monthly plan'
    },
    {
      id: 'priority-support',
      readiness: 'ready',
      priceMode: 'monthly',
      monthlyUSD: 150,
      monthlyTWD: 4700
    },
    {
      id: 'custom-operations',
      readiness: 'case_by_case',
      priceMode: 'quote',
      priceLabel: 'Quoted by workload'
    }
  ]
};

export const readinessLabels = {
  ready: 'Ready',
  pilot: 'Pilot',
  case_by_case: 'Case by case',
  learning: 'Learning'
};

export const categoryLabels = {
  network_marketplace: 'Network / marketplace',
  platform_tenant: 'Platform tenant',
  vertical_pilot: 'Vertical pilot'
};
