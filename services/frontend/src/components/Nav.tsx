import { Link, useLocation } from 'react-router-dom';

export function Nav() {
  const location = useLocation();
  
  const links = [
    { path: '/', label: 'Dashboard' },
    { path: '/teams', label: 'Teams' },
    { path: '/projects', label: 'Projects' },
    { path: '/users', label: 'Users' }
  ];

  return (
    <nav className="bg-gray-100 border-b border-gray-300">
      <div className="container mx-auto px-4">
        <ul className="flex space-x-6 py-3">
          {links.map(link => (
            <li key={link.path}>
              <Link
                to={link.path}
                className={`hover:text-primary transition-colors ${
                  location.pathname === link.path 
                    ? 'text-primary font-semibold' 
                    : 'text-gray-700'
                }`}
              >
                {link.label}
              </Link>
            </li>
          ))}
        </ul>
      </div>
    </nav>
  );
}

