const fs = require('fs');
const path = require('path');
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const root = path.resolve(__dirname, '..');
(async () => {
  const browser = await chromium.launch({headless:true, args:['--no-sandbox']});
  try {
    const page = await browser.newPage({viewport:{width:1440,height:1000}});
    await page.route('**/*', route => {
      const u = new URL(route.request().url());
      return ['localhost','127.0.0.1'].includes(u.hostname) ? route.continue() : route.abort();
    });
    const errors = [];
    page.on('pageerror', e => errors.push(e.message.slice(0,300)));
    const response = await page.goto('http://localhost:3300/login', {waitUntil:'networkidle',timeout:45000});
    await page.screenshot({path:path.join(root,'deliverables/01-foundation/learnhouse-login.png'),fullPage:true});
    const report = {
      scope:'Unmodified upstream login only; not the education V2 Demo',
      http_status: response.status(), title:await page.title(),
      password_inputs:await page.locator('input[type=password]').count(),
      email_inputs:await page.locator('input[type=email]').count(),
      page_errors: errors,
      passed:response.status()===200 && await page.locator('input[type=password]').count()===1 && errors.length===0
    };
    fs.writeFileSync(path.join(root,'deliverables/01-foundation/frontend-browser-results.json'),JSON.stringify(report,null,2));
    console.log(JSON.stringify(report));
    if(!report.passed) process.exitCode=1;
  } finally { await browser.close(); }
})().catch(e=>{ console.error(e.message);process.exitCode=1; });
