import http from 'k6/http';
import { sleep } from 'k6';

export const options = {
  stages: [
    { duration: '20s', target: 30 },
    { duration: '1m', target: 50 },
    { duration: '20s', target: 0 },
  ],
};

export default function () {
  http.get('http://localhost:8080');
  sleep(0.1);
}