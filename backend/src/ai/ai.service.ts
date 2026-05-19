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

  async generateActionDetails(profile: any, scholarship: any, missingDocs: string[]): Promise<any> {
    const studentName = profile.name || 'Student';
    const university = profile.university || 'FAST NUCES Lahore';
    const cgpa = profile.cgpa || '3.75';
    const field = profile.field_of_study || 'Software Engineering';
    const degree = profile.degree_level || 'Bachelor';

    const systemPrompt = `You are the Action Execution Agent (ACTOR) for Wazifa AI, a premium scholarship intelligence platform for Pakistani students.
Your job is to generate real, high-quality, academic-toned application artifacts.

You must output a single, raw JSON object (with no markdown block formatting, no extra explanation text, and no backticks) structured exactly like this:
{
  "simulatedForm": {
    "scholarshipName": "Scholarship Name",
    "applicantName": "Student's Full Name",
    "previousInstitution": "University Name",
    "cgpa": "Student CGPA",
    "major": "Field of Study",
    "applicationStatus": "DRAFT_COMPLETED",
    "completeness": "85%"
  },
  "professorEmail": "Subject: Recommendation Letter Request - Student Name\\n\\nDear Professor,\\n\\nI hope this email finds you well...",
  "calendarEvent": {
    "title": "Submit Scholarship Name Application",
    "deadline": "Scholarship Deadline",
    "description": "Calculated milestone deadlines: 1. Apply for missing [Missing Documents List] by [Calculated milestone date]. 2. Follow up with Professor. 3. Finalize SOP and submit by [Deadline]."
  },
  "sopIntro": "Statement of purpose opening paragraph (academic, professional tone) starting with 'As a dedicated graduate in...'"
}

Make sure:
1. The academic tone is highly polished, professional, and tailored.
2. The recommendation request email to the professor is pre-filled with student details, scholarship details, and references the student's background under their class.
3. The calendar description calculates milestone sub-deadlines relative to the deadline (${scholarship.deadline || 'November 15, 2026'}). Domicile takes 2-3 weeks to get, so schedule its milestone accordingly!
4. Do not include markdown code block characters (\`\`\`json or \`\`\`) in your response. Just return raw JSON.`;

    const userPrompt = `Student Profile:
- Name: ${studentName}
- University: ${university}
- CGPA: ${cgpa}
- Field: ${field}
- Degree: ${degree}

Scholarship:
- Name: ${scholarship.name}
- Country: ${scholarship.country}
- Deadline: ${scholarship.deadline}
- Required Documents: ${JSON.stringify(scholarship.required_documents)}
- Missing Documents: ${JSON.stringify(missingDocs)}`;

    try {
      const response = await this.openai.chat.completions.create({
        model: this.modelName,
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt }
        ],
        temperature: 0.2,
      });

      let content = response.choices[0]?.message?.content || '';
      this.logger.log('Raw ACTOR agent response received.');

      // Clean up markdown block wrapping if present
      content = content.replace(/```json/g, '').replace(/```/g, '').trim();

      return JSON.parse(content);
    } catch (e) {
      this.logger.error(`Error generating actor details from LLM: ${e.message}. Using high-quality fallback.`);
      return {
        simulatedForm: {
          scholarshipName: scholarship.name,
          applicantName: studentName,
          previousInstitution: university,
          cgpa: cgpa,
          major: field,
          applicationStatus: 'DRAFT_COMPLETED',
          completeness: '85%'
        },
        professorEmail: `Subject: Recommendation Letter Request - ${studentName} (${university})\n\nDear Professor,\n\nI hope this email finds you well. I am writing to request a recommendation letter for my application to the "${scholarship.name}".\n\nAs my professor at ${university} where I completed my ${degree} in ${field} (graduating with a CGPA of ${cgpa}), your academic endorsement would significantly strengthen my candidacy.\n\nWarm regards,\n${studentName}`,
        calendarEvent: {
          title: `Submit ${scholarship.name} Application`,
          deadline: scholarship.deadline || 'November 15, 2026',
          description: `Calculated milestones: 1. Apply for missing [${missingDocs.join(', ')}] immediately. 2. Finalize recommendation request. 3. Submit portal form before ${scholarship.deadline || 'November 15, 2026'}.`
        },
        sopIntro: `As a dedicated graduate in ${field} from ${university} with a CGPA of ${cgpa}, my academic excellence and research drive inspire my aspiration to pursue advanced studies. Securing the prestigious ${scholarship.name} represents the ideal catalyst to align my background with impactful global solutions, contributing directly to technological progress in Pakistan.`
      };
    }
  }
}
