import { Module } from '@nestjs/common';
import { SupabaseModule } from '../supabase/supabase.module';
import { ScholarshipController } from './scholarship.controller';
import { ScholarshipService } from './scholarship.service';

@Module({
  imports: [SupabaseModule],
  controllers: [ScholarshipController],
  providers: [ScholarshipService],
  exports: [ScholarshipService],
})
export class ScholarshipModule {}
