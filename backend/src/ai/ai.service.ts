import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import OpenAI from 'openai';
import { Observable } from 'rxjs';

@Injectable()
export class AiService {
  private readonly openai: OpenAI;
  private readonly logger = new Logger(AiService.name);

  constructor(private configService: ConfigService) {
    const apiKey = this.configService.get<string>('OPENAI_API_KEY');
    if (!apiKey) {
      this.logger.warn('OPENAI_API_KEY is missing. AI features will not work.');
    }
    this.openai = new OpenAI({ apiKey: apiKey || 'dummy-key' });
  }

  streamChat(message: string): Observable<{ data: any }> {
    return new Observable((subscriber) => {
      this.openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: [{ role: 'user', content: message }],
        stream: true,
      })
      .then(async (stream) => {
        try {
          for await (const chunk of stream) {
            const content = chunk.choices[0]?.delta?.content || '';
            if (content) {
              subscriber.next({ data: { content } });
            }
          }
          subscriber.complete();
        } catch (error) {
          subscriber.error(error);
        }
      })
      .catch((err) => subscriber.error(err));
    });
  }
}
