import axios from 'axios'
const service = axios.create({
  baseURL: import.meta.env.VITE_APP_URL,
  timeout: 180000,
  withCredentials: true,
  headers: {
    'Content-Type': 'application/json',
  },
})
service.interceptors.request.use(
  (config) => {
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

service.interceptors.response.use(
  function(response) {
    return response
  },
  function(error) {

    return Promise.reject(error)
  }
)
export default service
