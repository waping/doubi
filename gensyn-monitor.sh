#!/bin/bash

# 钉钉机器人 Webhook 地址，替换为你的实际地址
DINGTALK_WEBHOOK="https://oapi.dingtalk.com/robot/send?access_token=7389421a5dd8bc6c01e9b804f7619055dc07dfaafede557e1d5662213bd73984"

# 目标地址列表，可添加多个地址
ADDRESSES=("0xFaD7C5e93f28257429569B854151A1B8DCD404c2" "0xCC7a23b50fF2370e6698663e4b40345d977170a6" "0xFaD7C5e93f28257429569B854151A1B8DCD404c2")

# 初始化消息内容
MESSAGE=""

for ADDRESS in "${ADDRESSES[@]}"; do
    # 目标网页地址，添加 tab=internal_txns 参数
    URL="https://gensyn-testnet.explorer.alchemy.com/address/$ADDRESS?tab=internal_txns"

    # 下载网页内容
    HTML_CONTENT=$(curl -s "$URL")

    # 提取 Addresses 最新更新时间，这里假设网页中有类似 <span class="address-update-time">2025-07-12 07:00:00</span> 的元素
    # 请根据实际网页结构调整正则表达式
    UPDATE_TIME=$(echo "$HTML_CONTENT" | grep -oP '<span class="address-update-time">\K[^<]+' | tail -n 1)

    if [ -z "$UPDATE_TIME" ]; then
        MESSAGE+="地址 $ADDRESS：未获取到最新更新时间，请检查网页结构。\n"
    else
        # 将更新时间转换为时间戳
        UPDATE_TIMESTAMP=$(date -d "$UPDATE_TIME" +%s)
        # 获取当前时间戳
        CURRENT_TIMESTAMP=$(date +%s)
        # 计算时间差（分钟）
        TIME_DIFF=$(( (CURRENT_TIMESTAMP - UPDATE_TIMESTAMP) / 60 ))

        if [ $TIME_DIFF -gt 15 ]; then
            MESSAGE+="地址 $ADDRESS：最新更新时间为 $UPDATE_TIME，已超过 15 分钟。\n"
        else
            MESSAGE+="地址 $ADDRESS：最新更新时间为 $UPDATE_TIME，未超过 15 分钟。\n"
        fi
    fi
done

# 发送钉钉消息
curl -s -X POST "$DINGTALK_WEBHOOK" \
-H "Content-Type: application/json" \
-d '{
    "msgtype": "text",
    "text": {
        "content": "'"$MESSAGE"'"
    }
}'