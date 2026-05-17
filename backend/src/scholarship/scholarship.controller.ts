import { Controller, Get, Post, Body, Req, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { SupabaseGuard } from '../auth/supabase.guard';
import { ScholarshipService } from './scholarship.service';

@ApiTags('scholarships')
@ApiBearerAuth()
@UseGuards(SupabaseGuard)
@Controller('api/v1/scholarships')
export class ScholarshipController {
  constructor(private readonly scholarshipService: ScholarshipService) {}

  @Get()
  @ApiOperation({ summary: 'Get all pre-seeded scholarships' })
  async getAll() {
    return this.scholarshipService.getAllScholarships();
  }

  @Get('matched')
  @ApiOperation({ summary: 'Get matched scholarships grouped by country' })
  async getMatched(@Req() req: any) {
    const userId = req.user.id;
    return this.scholarshipService.getMatchedScholarships(userId);
  }

  @Post('apply')
  @ApiOperation({ summary: 'Run Action Simulation Engine' })
  async apply(@Req() req: any, @Body('scholarshipId') scholarshipId: string) {
    const userId = req.user.id;
    return this.scholarshipService.runActionEngine(userId, scholarshipId);
  }

  @Get('traces')
  @ApiOperation({ summary: 'Get live action traces for the debug panel' })
  async getTraces(@Req() req: any) {
    const userId = req.user.id;
    return this.scholarshipService.getTraces(userId);
  }
}
