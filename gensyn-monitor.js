const puppeteer = require('puppeteer');
const axios = require('axios');

// 钉钉机器人 Webhook 地址，替换为你的实际地址
const DINGTALK_WEBHOOK = 'https://oapi.dingtalk.com/robot/send?access_token=7389421a5dd8bc6c01e9b804f7619055dc07dfaafede557e1d5662213bd73984';
// 目标地址列表，可添加多个地址
const ADDRESSES = [
    '0xFaD7C5e93f28257429569B854151A1B8DCD404c2'
];

async function monitor() {
    let message = '';
    const browser = await puppeteer.launch({ headless: "new" });
    const page = await browser.newPage();

    for (const address of ADDRESSES) {
        const url = `https://gensyn-testnet.explorer.alchemy.com/address/${address}?tab=internal_txns`;
        await page.goto(url, { waitUntil: 'networkidle2' });

        try {
            // 等待包含 Parent txn hash 时间的元素加载，需要根据实际网页结构调整选择器
            const lastUpdateElement = await page.waitForSelector('.your-selector-for-last-update-time', { timeout: 10000 });
            const lastUpdateTime = await page.evaluate(el => el.textContent.trim(), lastUpdateElement);

            const currentDate = new Date();
            const lastUpdateDate = new Date(lastUpdateTime);
            const timeDiff = (currentDate - lastUpdateDate) / (1000 * 60);

            if (timeDiff > 15) {
                message += `地址 ${address}：Parent txn hash 最新更新时间为 ${lastUpdateTime}，已超过 15 分钟。\n`;
            } else {
                message += `地址 ${address}：Parent txn hash 最新更新时间为 ${lastUpdateTime}，未超过 15 分钟。\n`;
            }
        } catch (error) {
            message += `地址 ${address}：未获取到 Parent txn hash 最新更新时间，请检查网页结构。错误信息：${error.message}\n`;
        }
    }

    await browser.close();

    // 发送钉钉消息
    if (message) {
        try {
            await axios.post(DINGTALK_WEBHOOK, {
                msgtype: 'text',
                text: {
                    content: message
                }
            }, {
                headers: {
                    'Content-Type': 'application/json'
                }
            });
            console.log('钉钉消息发送成功');
        } catch (error) {
            console.error('钉钉消息发送失败', error);
        }
    }
}

monitor();