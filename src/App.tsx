import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from './hooks/useAuth';
import { AuthScreen } from './components/auth/AuthScreen';
import { AdminDashboard } from './components/admin/AdminDashboard';
import { UserDashboard } from './components/user/UserDashboard';
import { NotificationSystem } from './components/notifications/NotificationSystem';
import { Toaster } from 'react-hot-toast';

const AppRoutes: React.FC = () => {
  const { user, loading, isAdmin } = useAuth();

  console.log('AppRoutes: user:', !!user, 'loading:', loading, 'isAdmin:', isAdmin);

 

  if (!user) {
    console.log('AppRoutes: No user, showing auth screen');
    return <AuthScreen />;
  }

  console.log('AppRoutes: User authenticated, showing dashboard');
  return (
    <>
      <Routes>
        <Route
          path="/"
          element={
            <Navigate
              to={isAdmin ? '/admin' : '/dashboard'}
              replace
            />
          }
        />
        <Route
          path="/admin"
          element={
            isAdmin ? <AdminDashboard /> : <Navigate to="/dashboard" replace />
          }
        />
        <Route
          path="/dashboard"
          element={<UserDashboard />}
        />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
      <NotificationSystem />
    </>
  );
};

function App() {
  console.log('App: Rendering');
  return (
    <>
      <Toaster 
        position="top-center"
        toastOptions={{
          duration: 4000,
          style: {
            background: '#1f2937',
            color: '#fff',
            borderRadius: '12px',
            padding: '16px',
            fontWeight: '500',
          },
          success: {
            iconTheme: {
              primary: '#10B981',
              secondary: '#fff',
            },
          },
          error: {
            iconTheme: {
              primary: '#EF4444',
              secondary: '#fff',
            },
          },
        }}
      />
      <Router>
        <div className="App">
          <AppRoutes />
        </div>
      </Router>
    </>
  );
}

export default App;