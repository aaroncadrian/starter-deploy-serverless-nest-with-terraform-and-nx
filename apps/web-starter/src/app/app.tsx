import NxWelcome from './nx-welcome';
import { BrowserRouter, Link, Route, Routes } from 'react-router-dom';
import { SettingsPage } from './settings-page';

export function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route
          index
          element={
            <>
              <ul>
                <li>
                  <Link to={'settings'}>Go to Settings</Link>
                </li>

                <li>
                  <Link to={'unknown'}>Go to Unknown Page</Link>
                </li>
              </ul>

              <NxWelcome title="web-starter" />
            </>
          }
        />

        <Route
          path={'settings'}
          element={
            <>
              <ul>
                <li>
                  <Link to={'/'}>Go Home</Link>
                </li>

                <li>
                  <Link to={'unknown'}>Go to Unknown Page</Link>
                </li>
              </ul>

              <SettingsPage />
            </>
          }
        />

        <Route
          path={'*'}
          element={
            <>
              <ul>
                <li>
                  <Link to={'/'}>Go Home</Link>
                </li>

                <li>
                  <Link to={'settings'}>Go to Settings</Link>
                </li>
              </ul>

              <div>Not found</div>
            </>
          }
        />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
