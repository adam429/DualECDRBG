
<template>
  <h1>Dual-EC Backdoor Attack</h1>
  <div class="main-area">
    <div v-if="randomList.data.length !== 0" style="margin-top: 0rem;margin-bottom: 1rem">
      <h4>s0:</h4>
      {{currentParam.s0.toString(16)}}
      <h4>P:</h4>
      {{currentParam.p.x + ', ' + currentParam.p.y}}
      <h4>Q:</h4>
      {{currentParam.q.x + ', ' + currentParam.q.y}}


    </div>
    <button @click="generateRandomBit">Generate Random Bits</button>
    <div >
      <ul >
        <li v-for="(item,index) in randomList.data" :key="index">{{item}}</li>
      </ul>
    </div>
  <div>
    <button v-if="randomList.data.length !== 0" @click="initAttack('ruby')">
      <div>Attack By Ruby</div>
      (Backend Computing)
    </button>
    <button v-if="randomList.data.length !== 0" @click="initAttack('JS')">Attack By JavaScript (Frontend Computing)</button>
  </div>
    <ul>
      <li v-for="(item,index) in predictedRandomListByAttacker.data" :key="index">{{item}}</li>
    </ul>
    <h1 v-if="predictedRandomListByAttacker.data.length!==0" :style="{'color': verificationResultDisplay==='Attack Failed.'?'red':'green'}">{{verificationResultDisplay}}</h1>
  </div>
</template>
<script setup>
import elliptic from 'elliptic'
const EC = elliptic.ec;//有一个s1，生成一个r1。根据r1*d获得s2,由s2 得到 r2
const ec = new EC('secp256k1')
import { ref, reactive, computed, watch } from 'vue'
import worker from './worker?worker&inline'

let Q = ''

let n = 0

let P = ''

const listLength = 10

const truncateLength = 2

const randomList = reactive(
    {data:[]}
)
const predictedRandomListByAttacker = reactive(
    {data:[]}
)
const currentParam = reactive({
  s0:0,
  p:{
    x:'',
    y:''
  },
  q:{
    x:'',
    y:''
  }
})

function generateRandomBit() {
  Q = ec.g.mul(new ec.n.constructor(Math.random() * 100))
  n = Math.floor(Math.random() * 1000)
  P = Q.mul(n)

  currentParam.q = {
    x: Q.getX().toString(16),
    y: Q.getY().toString(16)
  }

  currentParam.p = {
    x: P.getX().toString(16),
    y: P.getY().toString(16)
  }

  currentParam.s0 = ec.genKeyPair().getPrivate()
  randomList.data = dualECGenerator2(currentParam.s0,listLength)
  predictedRandomListByAttacker.data.length = 0
}

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

const r1 = computed(()=>{
  return randomList.data[0]
})
const r2 = computed(()=>{
  return randomList.data[1]
})

const myWorkerList = []
const totalWorkerNum = 8
for(let i = 0;i < totalWorkerNum;i++)     {
  myWorkerList[i] = new worker()
  myWorkerList[i].onmessage= e => {
    predictedRandomListByAttacker.data.push(...e.data)
    judger(predictedRandomListByAttacker.data, randomList.data)
  }
}

function judger(listA,listB) {
  let result = ''
  let judgeLength = listA.length
  if(listB.length < listA.length) {
    judgeLength = listB.length
  }
  for(let i = 0;i<judgeLength;i++) {
    if(listA[i] !== listB[i]) {
      result = 'Attack Failed.'
      alert(result)
      verificationResultDisplay.value = result
      return
    }
  }
  result = 'Congratulation! Attack Successfully!'
  alert(result)
  verificationResultDisplay.value = result
}


import { getPredictedListByRuby } from './api/attack.js'

const verificationResultDisplay = ref('')

function initAttack(method) {
  predictedRandomListByAttacker.data = []
  if (method === 'ruby') {
    getPredictedListByRuby(
        {
          "px": "0x" + currentParam.p.x,
          "py": "0x" + currentParam.p.y,
          "qx": "0x" + currentParam.q.x,
          "qy": "0x" + currentParam.q.y,
          "rand1": "0x" + r1.value,
          "rand2": "0x" + r2.value
        }
    ).then((data) => {
      predictedRandomListByAttacker.data = []
      console.log(data.data)
      const result = data.data.result
      result.forEach((item, index) => {
        let makeupZero = 64 - truncateLength - result[index].length
        while (makeupZero !== 0) {
          result[index] = '0' + result[index]
          makeupZero--
        }
      })
      predictedRandomListByAttacker.data.push(r1.value, r2.value, ...data.data.result)
      judger(predictedRandomListByAttacker.data, randomList.data)
    })
    return
  }

  function getNByBruteForce(P, Q) {
    for (let i = 0; i < 10000; i++) {
      if (P.eq(Q.mul(new ec.n.constructor(i)))) return i
    }
    return -1
  }

  setTimeout(() => {
    myWorkerList.forEach((item, index) => {
      item.postMessage({
        listLength,
        totalWorkerNum,
        workerId: index,
        P: {
          x: P.getX().toString(16),
          y: P.getY().toString(16)
        },
        Q: {
          x: Q.getX().toString(16),
          y: Q.getY().toString(16)
        },
        n: getNByBruteForce(P, Q),
        r1: r1.value,
        r2: r2.value,
        truncateLength
      })
    })
  }, 10)

}


</script>
<style scoped>
h1{
  text-align: center;
}
.main-area{
  //margin-top: 6rem;
  width:100%;
  display:flex;
  flex-direction: column;
  align-items: center;
}
</style>
