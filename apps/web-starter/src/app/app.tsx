import NxWelcome from './nx-welcome';
import { BrowserRouter, Link, Route, Routes } from 'react-router-dom';
import { SettingsPage } from './settings-page';
import { PeoplePage } from './people-page';

const Navigation = () => {
  return (
    <ul>
      <li>
        <Link to={'/'}>Home</Link>
      </li>

      <li>
        <Link to={'/people'}>People</Link>
      </li>

      <li>
        <Link to={'/settings'}>Settings</Link>
      </li>

      <li>
        <Link to={'/unknown'}>Unknown</Link>
      </li>
    </ul>
  );
};

export function App() {
  return (
    <BrowserRouter>
      <Navigation />

      <Routes>
        <Route index element={<NxWelcome title="web-starter" />} />

        <Route path={'settings'} element={<SettingsPage />} />

        <Route path={'people'} element={<PeoplePage />} />

        <Route path={'*'} element={<div>Not found</div>} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
