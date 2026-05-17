import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import * as fs from 'fs';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Swagger setup
  const config = new DocumentBuilder()
    .setTitle('Wazifa AI API')
    .setDescription('The Wazifa backend API description')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
  
  const documentFactory = () => SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, documentFactory);

  // Generate swagger.json file for frontend devs
  fs.writeFileSync('./swagger.json', JSON.stringify(documentFactory(), null, 2));

  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
