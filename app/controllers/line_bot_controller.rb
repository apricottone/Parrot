class LineBotController < ApplicationController
    protect_from_forgery except: [:callback]
    
    def callback
        # 署名の検証用
        body = request.body.read
        # ヘッダー内の署名
        signature = request.env['HTTP_X_LINE_SIGNATURE']
        # 署名の検証
        unless client.validate_signature(body, signature)
            return head :bad_request # false => ERROR:400
        end

        events = client.parse_events_from(body) # 配列化
        events.each do |event|
            case event
            when Line::Bot::Event::Message
                case event.type
                when Line::Bot::Event::MessageType::Text
                    # テキストメッセージの抽出
                    message = {
                        type: 'text',
                        text: event.message['text']
                    }
                    client.reply_message(event['replyToken'], message)
                end
            end
        end
        head :ok # status_code: 200
    end

    private
        def client
            @client ||= Line::Bot::Client.new { |config|
                config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
                config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
            }
        end
end
