import { Controller, Post, Body, HttpCode, HttpStatus, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiProperty } from '@nestjs/swagger';
import { SupabaseService } from '../supabase/supabase.service';

class AuthDto {
  @ApiProperty({ example: 'user@example.com' })
  email: string;

  @ApiProperty({ example: 'password123', required: false })
  password?: string;
}

class AuthResponseDto {
  @ApiProperty({ example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' })
  accessToken: string;
}

@ApiTags('auth')
@Controller('api/v1/auth')
export class AuthController {
  constructor(private readonly supabaseService: SupabaseService) {}
  
  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Login with email and password' })
  @ApiResponse({ status: 200, description: 'Successful login', type: AuthResponseDto })
  async login(@Body() authDto: AuthDto): Promise<AuthResponseDto> {
    if (!authDto.password) throw new BadRequestException('Password required for login');
    
    const { data, error } = await this.supabaseService.getClient().auth.signInWithPassword({
      email: authDto.email,
      password: authDto.password,
    });

    if (error || !data.session) {
      throw new UnauthorizedException(error?.message || 'Login failed');
    }

    return { accessToken: data.session.access_token };
  }

  @Post('register')
  @ApiOperation({ summary: 'Register with email and password' })
  @ApiResponse({ status: 201, description: 'User successfully registered', type: AuthResponseDto })
  async register(@Body() authDto: AuthDto): Promise<AuthResponseDto> {
    if (!authDto.password) throw new BadRequestException('Password required for registration');

    const { data, error } = await this.supabaseService.getClient().auth.signUp({
      email: authDto.email,
      password: authDto.password,
    });

    if (error) {
      throw new BadRequestException(error.message);
    }
    
    // If email confirmation is off, session is returned immediately.
    // Otherwise, we might not have a session yet.
    return { accessToken: data.session?.access_token || 'check-email-for-confirmation' };
  }
}
