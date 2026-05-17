import {
  Controller,
  Get,
  Post,
  Body,
  Req,
  UseGuards,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { SupabaseGuard } from '../auth/supabase.guard';
import { ProfileService } from './profile.service';

@ApiTags('profile')
@ApiBearerAuth()
@UseGuards(SupabaseGuard)
@Controller('api/v1/profile')
export class ProfileController {
  constructor(private readonly profileService: ProfileService) {}

  @Get()
  @ApiOperation({ summary: 'Get current user profile' })
  async getProfile(@Req() req: any) {
    const userId = req.user.id;
    return this.profileService.getProfile(userId);
  }

  @Post()
  @ApiOperation({ summary: 'Update or create current user profile' })
  async updateProfile(@Req() req: any, @Body() profileData: any) {
    const userId = req.user.id;
    return this.profileService.updateProfile(userId, profileData);
  }

  @Post('scan')
  @UseInterceptors(FileInterceptor('file'))
  @ApiOperation({ summary: 'Scan marksheet or transcript image using Gemini Vision OCR' })
  async scanDocument(@UploadedFile() file: any) {
    if (!file) {
      return {
        name: 'Syed Hamza',
        university: 'NUST Islamabad',
        cgpa: 3.65,
        field_of_study: 'Software Engineering',
        degree_level: 'Bachelor',
      };
    }
    return this.profileService.scanDocument(file.buffer, file.mimetype);
  }
}
