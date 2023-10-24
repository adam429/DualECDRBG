import elliptic from 'elliptic'
const EC = elliptic.ec;
const ec = new EC('secp256k1')
self.addEventListener('message', e => {  //multi-thread computing
    let {
        listLength,
        totalWorkerNum,
            workerId,
        P,
        Q,
        n,
        r1,
        r2,
        truncateLength
    } = e.data


    P = ec.curve.point(P.x, P.y)

    Q = ec.curve.point(Q.x, Q.y)

    console.log(P,Q,e.data)

    function dualECGenerator2(s0, num) {
        const randomList = []
        let s = s0

        for(let i = 0; i < num; i++) {

            s = P.mul(s).getX()

            let r = Q.mul(s).getX().toString(16)
            while (r.length < 64) {
                r = '0' + r
            }
            r = r.substring(truncateLength)
            randomList.push(r)
        }
        return randomList
    }

    let round = -1
    let r1Predict = ''

    let s2ByAttacker = ''
    let r2ByAttacker = ''


    while(r2ByAttacker !== r2) {
        round++

        const tryNum = round * totalWorkerNum + workerId
        // console.log(tryNum)
        if(tryNum > Math.pow(2,4 * truncateLength)) break

        r1Predict = tryNum.toString(16) + r1



        try {
            s2ByAttacker = ec.curve.pointFromX(r1Predict, 0).mul(new ec.n.constructor(n)).getX()
            // console.log(s2ByAttacker)
        } catch (e) {
            continue
        }

        r2ByAttacker = Q.mul(s2ByAttacker).getX().toString(16).substring(truncateLength)


    }

    const predictRandomListByAttacker = [r1,r2]

    if(r2ByAttacker === r2) {
        predictRandomListByAttacker.push(...dualECGenerator2(s2ByAttacker, 10))

        self.postMessage(predictRandomListByAttacker)

    }
    }
)