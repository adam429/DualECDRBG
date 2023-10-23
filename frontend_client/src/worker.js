import elliptic from 'elliptic'
const EC = elliptic.ec;//有一个s1，生成一个r1。根据r1*d获得s2,由s2 得到 r2
const ec = new EC('secp256k1')
self.addEventListener('message', e => {
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

    // r1 = "1d936baef8f07830895d3478a5c8bae129474702798db6a70d8025b7c580a"
    // r2 = "1b55f36800db1ff5770a57989ef70dc9ca6ee6799c6f1017a3b36582761f2f"
    //
    //
    // P = ec.curve.point("51981691a5f1d8df1cafb95a738b9e3ed036ce54f10a74470c470cc2e80f37ad", "9fb904767cf2a990766e3c26e97f045d03fabdc471ef664d31aa662c5972261")
    //
    // Q = ec.curve.point("79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798", "483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8")

    console.log(P,Q,e.data)



    function dualECGenerator2(s0, num) {
        const randomList = []
        let s = s0

        for(let i = 0; i < num; i++) {

            s = P.mul(s).getX()
            // console.log(Q.mul(s).getX().toString(16))

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
    let r1Predict = ''//tryNum.toString(16) + r1
    // console.log(r1Predict)

    let s2ByAttacker = ''//ec.curve.pointFromX(r1Predict, 0).mul(new ec.n.constructor(getNByBruteForce(P, Q))).getX()
    let r2ByAttacker = ''//Q.mul(s2ByAttacker).getX().toString(16)


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
        // s2ByAttacker = ec.curve.pointFromX(r1Predict, 0).mul(new ec.n.constructor(getNByBruteForce(P, Q))).getX()
        // const predictRandomListByAttacker = []
        // console.log(Q.getX().toString(16))
        r2ByAttacker = Q.mul(s2ByAttacker).getX().toString(16).substring(truncateLength)


    }
    // const s2ByAttacker = ec.curve.pointFromX(r1, 0).mul(new ec.n.constructor(getNByBruteForce(P, Q))).getX()
    const predictRandomListByAttacker = [r1,r2]
    // let r2ByAttacker = Q.mul(s2ByAttacker).getX().toString(16)
    if(r2ByAttacker === r2) {
        predictRandomListByAttacker.push(...dualECGenerator2(s2ByAttacker, 10))
        // console.log(predictRandomListByAttacker,workerId)
        // let timeB = new Date()
        // console.log(timeB.getTime(), 'multi thread end time')
        self.postMessage(predictRandomListByAttacker)
        // return predictRandomListByAttacker
    }
    }
)