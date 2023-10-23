import request from './request.js'

export function getPredictedListByRuby(data) { //api
    return request({
        url: '/attack',
        method: 'POST',
        data
    })
}

