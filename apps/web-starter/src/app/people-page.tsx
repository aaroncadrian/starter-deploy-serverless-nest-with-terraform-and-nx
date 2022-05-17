import axios from 'axios';
import { useEffect, useState } from 'react';
import { environment } from '../environments/environment';

export const PeoplePage = () => {
  const [{ loading, data, error }, setHttpState] = useState<{
    data?: unknown[];
    error?: unknown;
    loading: boolean;
  }>({
    loading: false,
  });

  useEffect(() => {
    setHttpState({
      loading: true,
    });

    axios
      .get<{ items: unknown[] }>('people', {
        baseURL: environment.svcStarter.baseUrl,
      })
      .then(({ data }) => {
        setHttpState({
          loading: false,
          data: data.items,
        });
      })
      .catch((err) => {
        setHttpState({
          loading: false,
          error: err,
        });
      });
  }, []);

  return (
    <div>
      <h1>People</h1>
      {loading ? (
        'Loading...'
      ) : error ? (
        <div>
          <h2>Error Loading People</h2>
          <pre>{JSON.stringify(error, null, 2)}</pre>
        </div>
      ) : (
        <div>
          <pre>{JSON.stringify(data, null, 2)}</pre>
        </div>
      )}
    </div>
  );
};
