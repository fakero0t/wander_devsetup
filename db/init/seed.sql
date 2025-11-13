-- Wander Database Seed Script
-- This script is idempotent and can be run multiple times safely

DO $$
DECLARE
  user_count INT;
BEGIN
  -- Idempotency check: Skip if data already exists
  SELECT COUNT(*) INTO user_count FROM information_schema.tables WHERE table_name = 'users';
  
  IF user_count > 0 THEN
    SELECT COUNT(*) INTO user_count FROM users;
    IF user_count > 0 THEN
      RAISE NOTICE 'Database already seeded. Skipping...';
      RETURN;
    END IF;
  END IF;

  -- Drop existing tables if they exist (CASCADE removes dependent objects)
  DROP TABLE IF EXISTS activities CASCADE;
  DROP TABLE IF EXISTS tasks CASCADE;
  DROP TABLE IF EXISTS projects CASCADE;
  DROP TABLE IF EXISTS team_members CASCADE;
  DROP TABLE IF EXISTS teams CASCADE;
  DROP TABLE IF EXISTS users CASCADE;

  -- Create users table
  CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  -- Create teams table
  CREATE TABLE teams (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  -- Create team_members table
  CREATE TABLE team_members (
    id SERIAL PRIMARY KEY,
    team_id INT NOT NULL REFERENCES teams(id) ON DELETE CASCADE ON UPDATE CASCADE,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(team_id, user_id)
  );

  -- Create projects table
  CREATE TABLE projects (
    id SERIAL PRIMARY KEY,
    team_id INT NOT NULL REFERENCES teams(id) ON DELETE CASCADE ON UPDATE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  -- Create tasks table
  CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,
    project_id INT NOT NULL REFERENCES projects(id) ON DELETE CASCADE ON UPDATE CASCADE,
    assigned_to INT REFERENCES users(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'todo',
    priority VARCHAR(50) DEFAULT 'medium',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  -- Create activities table
  CREATE TABLE activities (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(100),
    entity_id INT,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  -- Create indexes for performance
  CREATE INDEX idx_users_email ON users(email);
  CREATE INDEX idx_team_members_user_id ON team_members(user_id);
  CREATE INDEX idx_team_members_team_id ON team_members(team_id);
  CREATE INDEX idx_projects_team_id ON projects(team_id);
  CREATE INDEX idx_tasks_project_id ON tasks(project_id);
  CREATE INDEX idx_tasks_assigned_to ON tasks(assigned_to);
  CREATE INDEX idx_tasks_status ON tasks(status);
  CREATE INDEX idx_activities_user_id ON activities(user_id);
  CREATE INDEX idx_activities_created_at ON activities(created_at);

  -- Insert seed data: Users
  INSERT INTO users (name, email, created_at, updated_at) VALUES
    ('Alice Chen', 'alice@wander.com', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
    ('Bob Martinez', 'bob@wander.com', NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
    ('Carol Singh', 'carol@wander.com', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
    ('David Lee', 'david@wander.com', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
    ('Emma Johnson', 'emma@wander.com', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days');

  -- Insert seed data: Teams (Categories for vacation rentals)
  INSERT INTO teams (name, description, created_at, updated_at) VALUES
    ('Ocean', 'Beachfront and coastal properties', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
    ('Mountain', 'Mountain views and alpine retreats', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
    ('Forest', 'Woodland cabins and nature escapes', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
    ('Lake', 'Lakeside properties and waterfront homes', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
    ('Desert', 'Desert landscapes and arid retreats', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
    ('Skiing', 'Ski-in/ski-out properties and winter retreats', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
    ('Hawaii', 'Tropical paradise properties', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
    ('Urban', 'City center properties and urban escapes', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days');

  -- Insert seed data: Team Members (not used in vacation rental context, keeping minimal data)
  INSERT INTO team_members (team_id, user_id, joined_at) VALUES
    (1, 1, NOW() - INTERVAL '7 days'),
    (2, 2, NOW() - INTERVAL '6 days');

  -- Insert seed data: Projects (Vacation Rental Properties)
  INSERT INTO projects (team_id, name, description, status, created_at, updated_at) VALUES
    (1, 'Wander Crystal Palms', 'Beachfront property with stunning ocean views and direct beach access', 'active', NOW() - INTERVAL '6 days', NOW() - INTERVAL '1 day'),
    (2, 'Wander Wimberley Hills', 'Mountain retreat with panoramic hill country views and modern amenities', 'active', NOW() - INTERVAL '5 days', NOW() - INTERVAL '2 days'),
    (3, 'Wander Concan River', 'Riverside property nestled in the forest with private river access', 'active', NOW() - INTERVAL '4 days', NOW() - INTERVAL '3 days'),
    (1, 'Wander Port Aransas', 'Coastal home with private pool and steps to the beach', 'active', NOW() - INTERVAL '3 days', NOW() - INTERVAL '2 days'),
    (4, 'Wander Lake Travis', 'Lakeside modern home with dock and water sports equipment', 'active', NOW() - INTERVAL '2 days', NOW() - INTERVAL '1 day'),
    (5, 'Wander Marfa Desert', 'Desert modern home with stargazing deck and minimalist design', 'active', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day');

  -- Insert seed data: Tasks (Reviews/Bookings - keeping minimal for demo)
  INSERT INTO tasks (project_id, assigned_to, title, description, status, priority, created_at, updated_at) VALUES
    (1, 1, 'Guest Review', 'Amazing beachfront location with stunning sunsets', 'done', 'high', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
    (2, 2, 'Guest Review', 'Perfect mountain retreat, highly recommend', 'done', 'high', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
    (3, 3, 'Guest Review', 'Peaceful riverside escape, exactly as described', 'done', 'medium', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day');

  -- Insert seed data: Activities (Booking activity log)
  INSERT INTO activities (user_id, action, entity_type, entity_id, description, created_at) VALUES
    (1, 'booked', 'project', 1, 'Alice Chen booked Wander Crystal Palms', NOW() - INTERVAL '3 days'),
    (2, 'booked', 'project', 2, 'Bob Martinez booked Wander Wimberley Hills', NOW() - INTERVAL '2 days'),
    (3, 'booked', 'project', 3, 'Carol Singh booked Wander Concan River', NOW() - INTERVAL '1 day'),
    (1, 'reviewed', 'project', 1, 'Alice Chen left a review for Wander Crystal Palms', NOW() - INTERVAL '3 days'),
    (2, 'reviewed', 'project', 2, 'Bob Martinez left a review for Wander Wimberley Hills', NOW() - INTERVAL '2 days'),
    (4, 'viewed', 'project', 4, 'David Lee viewed Wander Port Aransas', NOW() - INTERVAL '1 day'),
    (5, 'viewed', 'project', 5, 'Emma Johnson viewed Wander Lake Travis', NOW() - INTERVAL '1 day');

  -- Success message
  RAISE NOTICE 'Database seeded successfully: 5 users, 5 categories, 6 properties, 3 reviews, 7 activities';

END $$;

