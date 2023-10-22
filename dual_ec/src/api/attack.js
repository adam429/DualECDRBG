import request from './request.js'

export function getPredictedListByRuby(data) {
    return request({
        url: '/attack',
        method: 'POST',
        data
    })
}

