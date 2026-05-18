import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import OpenAI from 'openai';
import { Observable } from 'rxjs';

@Injectable()
export class AiService {
  private readonly openai: OpenAI;
  private readonly logger = new Logger(AiService.name);

  private readonly modelName: string;

  constructor(private configService: ConfigService) {
    let apiKey = this.configService.get<string>('OPENAI_API_KEY');
    const geminiKey = this.configService.get<string>('OPEN_API_KEY');

    if (!apiKey && geminiKey && geminiKey.startsWith('AIzaSy')) {
      // Configure OpenAI client with Google Gemini compatibility layer
      this.logger.log('Configuring OpenAI client compatibility layer with Google Gemini API.');
      this.openai = new OpenAI({
        apiKey: geminiKey,
        baseURL: 'https://generativelanguage.googleapis.com/v1beta/openai/',
      });
      this.modelName = 'gemini-2.5-flash';
    } else {
      if (!apiKey) {
        this.logger.warn('Neither OPENAI_API_KEY nor active OPEN_API_KEY (Gemini) is available. Falling back to dummy credentials.');
      }
      this.openai = new OpenAI({ apiKey: apiKey || 'dummy-key' });
      this.modelName = 'gpt-4o-mini';
    }
  }

  streamChat(message: string): Observable<{ data: any }> {
    return new Observable((subscriber) => {
      this.openai.chat.completions.create({
        model: this.modelName,
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
