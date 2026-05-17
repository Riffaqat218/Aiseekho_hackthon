import { Controller, Post, Get, Body, Param, Req, UseGuards, Sse } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiProperty, ApiBearerAuth } from '@nestjs/swagger';
import { SupabaseGuard } from '../auth/supabase.guard';
import { AiService } from '../ai/ai.service';
import { Observable } from 'rxjs';

class ChatMessageDto {
  @ApiProperty({ example: 'Hello AI, how are you?' })
  message: string;
}

class ChatResponseDto {
  @ApiProperty({ example: 'I am doing well, thank you!' })
  reply: string;
}

class ChatHistoryDto {
  @ApiProperty({ example: 'msg_123' })
  id: string;
  @ApiProperty({ example: 'user' })
  role: string;
  @ApiProperty({ example: 'Hello AI' })
  content: string;
}

@ApiTags('chat')
@ApiBearerAuth()
@UseGuards(SupabaseGuard)
@Controller('api/v1/chat')
export class ChatController {
  constructor(private readonly aiService: AiService) {}
  
  @Post('send')
  @ApiOperation({ summary: 'Send a message to the AI (non-streaming for mock)' })
  @ApiResponse({ status: 200, description: 'AI Reply', type: ChatResponseDto })
  async sendMessage(@Body() chatDto: ChatMessageDto): Promise<ChatResponseDto> {
    return { reply: 'Mock AI Response' };
  }

  @Post('stream')
  @Sse()
  @ApiOperation({ summary: 'Stream AI response (Server-Sent Events)' })
  streamMessage(@Body() chatDto: ChatMessageDto): Observable<{ data: any }> {
    return this.aiService.streamChat(chatDto.message);
  }

  @Get('history')
  @ApiOperation({ summary: 'Get user conversation history' })
  @ApiResponse({ status: 200, description: 'List of past messages', type: [ChatHistoryDto] })
  async getHistory(): Promise<ChatHistoryDto[]> {
    return [
      { id: '1', role: 'user', content: 'Hello' },
      { id: '2', role: 'ai', content: 'Hi there!' }
    ];
  }
}
