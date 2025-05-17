# Link2Chat Supabase Integration

This directory contains the Supabase database schema and setup instructions for the Link2Chat application.

## Setup Instructions

### 1. Create a Supabase Project

1. Go to [Supabase.com](https://supabase.com) and create a new account if you don't have one
2. Create a new project and make note of your project URL and anon key

### 2. Initialize the Database Schema

1. Navigate to the SQL Editor in your Supabase dashboard
2. Copy the contents of `schema.sql` in this directory
3. Paste the SQL into the SQL Editor and click "Run"
4. Verify that all tables are created successfully

### 3. Configure Your Flutter App

1. Open `lib/core/config/constants.dart` in your Flutter project
2. Replace the placeholder values with your actual Supabase credentials:

```dart
// Supabase Configuration
static const String supabaseUrl = 'https://your-project-id.supabase.co';
static const String supabaseAnonKey = 'your-anon-key';
```

### 4. Enable Authentication

1. In your Supabase dashboard, go to Authentication → Settings
2. Enable Email Auth provider and configure as needed
3. Set up any additional authentication providers you want to use

### 5. Set Up Storage (Optional)

If you want to use Supabase Storage for storing images or other files:

1. Go to Storage in your Supabase dashboard
2. Create a new bucket called "avatars" for user profile images
3. Set up the appropriate bucket policies

## Features

The Supabase integration provides:

- User authentication and management
- Cloud database for phone entries and analytics
- Team management and sharing
- API key generation and management
- Real-time sync for offline support

## Database Schema

- **users**: Extends Supabase's auth.users table with application-specific user data
- **phone_entries**: Stores the WhatsApp/Telegram links with associated metadata
- **teams**: Supports team feature with roles and permissions
- **team_members**: Manages team membership
- **api_keys**: Allows generation and management of API keys

## Row Level Security (RLS)

All tables have RLS policies set up to ensure users can only access their own data, or data shared with them via teams.

## Real-time Sync

Supabase's real-time feature is enabled for phone_entries, teams, and team_members tables to support real-time updates across devices.

## Troubleshooting

If you encounter issues with the Supabase integration:

1. Check that your Supabase URL and anon key are correct
2. Verify that the database schema was applied correctly
3. Check the Flutter app logs for connectivity or authentication errors
4. Ensure that Row Level Security policies are correctly applied

For more help, refer to the [Supabase documentation](https://supabase.com/docs).
