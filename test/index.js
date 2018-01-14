/* eslint-env node, mocha */
const puppeteer = require('puppeteer')
const jsc = require('jsverify')

const LAUNCH_OPTIONS = process.env.CHROMIUM_PATH
  ? { executablePath: process.env.CHROMIUM_PATH }
  : { }

const URL = 'http://localhost:8000/test/Main.elm'

/**
 * The mocha test suite
 */
describe('Counter', function () {
  var browser

  before(async () => {
    browser = await puppeteer.launch(LAUNCH_OPTIONS)
  })

  after(async () => {
    await browser.close()
  })

  it('works', async () => {
    await jsc.assert(jsc.forall(events, async (events) => {
      // create a new page
      const page = await browser.newPage()

      const simulatedCounter = await simulate(page, events)
      const expectedCounter = expect(events)
      console.log(events, simulatedCounter, expectedCounter)

      // close the page
      await page.close()

      return simulatedCounter === expectedCounter
    }))
  }).timeout(0)
})

/**
 * JSVerify arbitary events
 */
const events = jsc.array(jsc.oneof([
  jsc.constant('Increase'),
  jsc.constant('Decrease'),
  jsc.constant('Reset')
]))

/**
 * Compute the expected value returned from simulation
 */
function expect (events) {
  return events.reduce((counter, event) => {
    switch (event) {
      case 'Increase':
        return counter + 1
      case 'Decrease':
        return counter - 1
      case 'Reset':
        return 0
    }
  }, 0)
}

/**
 * Fire up a headless chrome and simulate the events
 */
async function simulate (page, events) {
  await page.goto(URL)

  // Wait until application is recompiled. See known limitations in Readme.
  await sleep(100)

  for (var i = 0; i < events.length; i++) {
    var event = events[i]

    switch (event) {
      case 'Increase':
        await increase(page)
        break

      case 'Decrease':
        await decrease(page)
        break

      case 'Reset':
        await reset(page)
        break

      default:
        throw new Error('Unknown event type')
    }
  }

  // Wait a moment for everything to be computed. See known limitations.
  await sleep(50)

  var counter = await getCounter(page)

  return counter
}

// Helpers to interact with Web application

/**
 * Get the current value of the counter
 */
function getCounter (page) {
  return page.$('#counter')
    .then(element => element.getProperty('innerHTML'))
    .then(inner => inner.jsonValue())
    .then(parseInt)
}

/**
 * Increase counter by n with ArrowUp
 */
async function increase (page, n) {
  n = n || 1
  for (var i = 0; i < n; i++) {
    await page.keyboard.press('ArrowUp')
  }
}

/**
 * Decrease counter by n with ArrowDown
 */
async function decrease (page, n) {
  n = n || 1
  for (var i = 0; i < n; i++) {
    await page.keyboard.press('ArrowDown')
  }
}

/**
 * Reset the counter
 */
function reset (page) {
  return page.click('#reset')
}

async function sleep (t) {
  return new Promise((resolve, reject) => {
    setTimeout(resolve, t)
  })
}
