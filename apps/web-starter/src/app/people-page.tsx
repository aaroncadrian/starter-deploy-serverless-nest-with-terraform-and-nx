import axios from 'axios';
import { useCallback, useEffect, useState } from 'react';
import { environment } from '../environments/environment';

export const PeoplePage = () => {
  const [{ loading, data, error }, setHttpState] = useState<{
    data?: unknown[];
    error?: unknown;
    loading: boolean;
  }>({
    loading: false,
  });

  const loadPeople = useCallback(() => {
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
  }, [setHttpState]);

  useEffect(() => {
    loadPeople();
  }, [loadPeople]);

  const createPerson = () => {
    axios.post<{ item: unknown[] }>(
      'people',
      {
        firstName: 'First',
        lastName: 'Last',
      },
      {
        baseURL: environment.svcStarter.baseUrl,
      }
    );
  };

  return (
    <div>
      <h1>People</h1>

      <button onClick={loadPeople} disabled={loading}>
        Refresh
      </button>

      <button onClick={createPerson}>Create Person</button>

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
