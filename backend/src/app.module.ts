import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { ChatModule } from './chat/chat.module';
import { SupabaseModule } from './supabase/supabase.module';
import { AiModule } from './ai/ai.module';
import { ProfileModule } from './profile/profile.module';
import { ScholarshipModule } from './scholarship/scholarship.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    AuthModule, 
    ChatModule, 
    SupabaseModule, 
    AiModule,
    ProfileModule,
    ScholarshipModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}

