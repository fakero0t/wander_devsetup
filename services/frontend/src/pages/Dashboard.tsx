import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { apiGet } from '@/api/client';
import { Project, Team } from '@wander/shared';

export function Dashboard() {
  const [loading, setLoading] = useState(true);
  const [properties, setProperties] = useState<Project[]>([]);
  const [categories, setCategories] = useState<Team[]>([]);
  const [selectedCategory, setSelectedCategory] = useState<string>('For you');

  useEffect(() => {
    Promise.all([
      apiGet<Project[]>('/api/projects'),
      apiGet<Team[]>('/api/teams')
    ])
      .then(([propertiesData, categoriesData]) => {
        setProperties(propertiesData);
        setCategories(categoriesData);
      })
      .catch(err => console.error('Failed to fetch data:', err))
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-900 text-white flex items-center justify-center">
        <div>Loading...</div>
      </div>
    );
  }

  // Get location names for properties
  const getLocation = (property: Project) => {
    if (property.name.includes('Crystal Palms')) return 'BOLIVAR PENINSULA, TEXAS';
    if (property.name.includes('Wimberley')) return 'WIMBERLEY, TEXAS';
    if (property.name.includes('Concan')) return 'SABINAL, TEXAS';
    if (property.name.includes('Port Aransas')) return 'PORT ARANSAS, TEXAS';
    if (property.name.includes('Lake Travis')) return 'AUSTIN, TEXAS';
    if (property.name.includes('Marfa')) return 'MARFA, TEXAS';
    const category = categories.find(c => c.id === property.team_id);
    return `${category?.name.toUpperCase() || 'TEXAS'}, TEXAS`;
  };

  const filteredProperties = selectedCategory === 'For you' 
    ? properties 
    : properties.filter(p => {
        const category = categories.find(c => c.id === p.team_id);
        return category?.name === selectedCategory;
      });

  // Additional categories from the real site
  const additionalCategories = ['Make An Offer', 'Skiing', 'Hawaii', 'Urban', 'Families', 'Groups', 'Pet-friendly', 'National parks', 'Holidays', 'Golf', 'Remote Work'];

  return (
    <div className="min-h-screen bg-gray-900 text-white">
      {/* Header Section */}
      <div className="pt-12 pb-8 px-4 text-center">
        <h1 className="text-5xl md:text-6xl font-bold mb-4">Find your happy place.</h1>
        <p className="text-lg md:text-xl text-gray-300 max-w-3xl mx-auto px-4">
          Never book a bad vacation home again. Every Wander comes with hotel-grade amenities, inspiring views, pristine cleaning and 24/7 concierge service.
        </p>
      </div>

      {/* Search Bar */}
      <div className="px-4 mb-6">
        <div className="max-w-4xl mx-auto bg-white rounded-full px-6 py-4 flex items-center shadow-lg">
          <svg className="w-6 h-6 text-gray-400 mr-3 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
          <input
            type="text"
            placeholder="Start your search"
            className="flex-1 outline-none text-gray-800 text-lg"
          />
        </div>
      </div>

      {/* Satisfaction Metric */}
      <div className="px-4 mb-8 text-center">
        <div className="inline-flex items-center text-sm text-gray-300">
          <svg className="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
            <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
          </svg>
          <span>96% guest satisfaction with 50,208 nights booked</span>
        </div>
      </div>

      {/* Category Navigation */}
      <div className="px-4 mb-8">
        <div className="flex space-x-6 overflow-x-auto pb-2 scrollbar-hide max-w-7xl mx-auto">
          {['For you', 'Make An Offer', ...categories.map(c => c.name), ...additionalCategories].map((cat) => (
            <button
              key={cat}
              onClick={() => setSelectedCategory(cat)}
              className={`whitespace-nowrap pb-2 transition-colors ${
                selectedCategory === cat
                  ? 'text-white border-b-2 border-white font-medium'
                  : 'text-gray-400 hover:text-white'
              }`}
            >
              {cat}
            </button>
          ))}
        </div>
      </div>

      {/* Property Listings */}
      <div className="px-4 mb-20">
        <div className="flex items-center justify-between mb-6 max-w-7xl mx-auto">
          <h2 className="text-2xl font-semibold">Available next weekend</h2>
          <span className="text-gray-400 cursor-pointer hover:text-white transition-colors">&gt;</span>
        </div>
        
        <div className="flex space-x-4 overflow-x-auto pb-4 scrollbar-hide max-w-7xl mx-auto">
          {filteredProperties.slice(0, 6).map((property) => {
            const location = getLocation(property);
            const category = categories.find(c => c.id === property.team_id);
            
            return (
              <Link
                key={property.id}
                to={`/projects/${property.id}`}
                className="flex-shrink-0 w-80 bg-gray-800 rounded-lg overflow-hidden hover:bg-gray-750 transition-colors"
              >
                {/* Property Image Placeholder */}
                <div className="w-full h-64 bg-gradient-to-br from-gray-700 to-gray-600 relative">
                  <div className="absolute top-3 left-3 bg-yellow-500 text-gray-900 text-xs font-semibold px-2 py-1 rounded">
                    Sweet deal
                  </div>
                  <div className="absolute top-3 right-3 bg-gray-900 bg-opacity-50 rounded-full p-2 hover:bg-opacity-70 transition-colors cursor-pointer">
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
                    </svg>
                  </div>
                </div>
                
                {/* Property Info */}
                <div className="p-4">
                  <div className="text-xs text-gray-400 mb-1 uppercase tracking-wide">{location}</div>
                  <h3 className="text-lg font-semibold mb-2">{property.name}</h3>
                  <div className="text-sm text-gray-300 mb-3">Next avail. Nov 19 - Nov 22</div>
                  <div className="flex items-center space-x-4 text-sm text-gray-400">
                    <div className="flex items-center">
                      <svg className="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                        <path d="M10.394 2.08a1 1 0 00-.788 0l-7 3a1 1 0 000 1.84L5.25 8.051a.999.999 0 01.356-.257l4-1.714a1 1 0 11.788 1.838L7.667 9.088l1.94.831a1 1 0 00.787 0l7-3a1 1 0 000-1.838l-7-3zM3.31 9.397L5 10.12v4.102a8.969 8.969 0 00-1.05-.174 1 1 0 01-.89-.89 11.115 11.115 0 01.25-3.762zM9.3 16.573A9.026 9.026 0 007 14.935v-3.957l1.818.78a3 3 0 002.364 0l5.508-2.361a11.026 11.026 0 01.25 3.762 1 1 0 01-.89.89 8.968 8.968 0 00-5.35 2.524 1 1 0 01-1.4 0zM6 18a1 1 0 001-1v-2.065a8.935 8.935 0 00-2-.712V17a1 1 0 001 1z" />
                      </svg>
                      <span>3</span>
                    </div>
                    <div className="flex items-center">
                      <svg className="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                        <path d="M9 6a3 3 0 11-6 0 3 3 0 016 0zM17 6a3 3 0 11-6 0 3 3 0 016 0zM12.93 17c.046-.327.07-.66.07-1a6.97 6.97 0 00-1.5-4.33A5 5 0 0119 16v1h-6.07zM6 11a5 5 0 015 5v1H1v-1a5 5 0 015-5z" />
                      </svg>
                      <span>10</span>
                    </div>
                    {property.id === 2 && (
                      <div className="flex items-center">
                        <svg className="w-4 h-4 mr-1 text-yellow-400" fill="currentColor" viewBox="0 0 20 20">
                          <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                        </svg>
                        <span>4.7</span>
                      </div>
                    )}
                  </div>
                </div>
              </Link>
            );
          })}
        </div>
      </div>

      {/* The Wander Difference Section */}
      <div className="bg-gray-800 py-16 px-4 mb-20">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-12">
            <h2 className="text-4xl font-bold mb-4">IT'S A VACATION HOME, BUT BETTER</h2>
            <p className="text-xl text-gray-300">The Wander difference</p>
          </div>
          
          <p className="text-center text-lg text-gray-300 mb-12 max-w-3xl mx-auto">
            Wander is different because we combine the quality of a luxury hotel with the comfort of a private vacation home. Your best trip ever is just a few clicks away.
          </p>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {[
              {
                title: 'Only the best homes',
                description: "We'll never not look like the pictures. Every Wander is beautiful and expertly operated, so you can leave any stress at the door."
              },
              {
                title: 'Hotel-grade amenities',
                description: "We'll never leave you with nothing to do. From ultra fast WiFi to gyms and pools, our homes make it easy to blend work and play."
              },
              {
                title: '24/7 concierge service',
                description: "We'll never leave you hanging. Our chat-based Concierge is always available to help – from trip questions to special requests."
              },
              {
                title: 'Inspiring and stunning views',
                description: "We'll never leave you uninspired. Every Wander has stunning views to refresh and inspire your soul. Adventure awaits."
              },
              {
                title: 'Meticulous cleaning',
                description: "We'll never have you check in to a dirty house. Our cleaning teams are meticulous, and there are no chores at checkout."
              },
              {
                title: 'Safety and security',
                description: "We'll never pass you off to a stranger. Every Wander location meets our industry-leading safety standards to give you peace of mind."
              }
            ].map((feature, idx) => (
              <div key={idx} className="bg-gray-900 p-6 rounded-lg">
                <h3 className="text-xl font-semibold mb-3">{feature.title}</h3>
                <p className="text-gray-300 leading-relaxed">{feature.description}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
