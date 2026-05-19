const { createClient } = require('@supabase/supabase-js');
const OpenAI = require('openai');

// 1. Supabase and OpenAI Keys
const SUPABASE_URL = 'https://ezsybiaqitlwplbxhqvb.supabase.co';
const SUPABASE_KEY = 'sb_secret_VNbk56APBV2-BwWbvrFNMw_bb0dtZeK';
const OPENAI_API_KEY = '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';

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);
const openai = new OpenAI({ apiKey: OPENAI_API_KEY });

const userId = 'a8e4c6a9-853c-4afc-bf15-43d0d381f4b3'; // Riffaqat's profile ID

async function runTestPipeline() {
  console.log('=====================================================');
  console.log('🚀 WAZEEFA AI PIPELINE TEST');
  console.log('=====================================================\n');

  // STEP 1: Update the user profile with custom mock info
  // (We omit columns like has_domicile that might be missing in your Supabase cache)
  console.log('📝 STEP 1: Saving & Updating Student Profile...');
  const profileUpdate = {
    id: userId,
    name: 'riffaqat hussain',
    university: 'numl',
    cgpa: 3.7,
    field_of_study: 'IT',
    degree_level: 'Bachelor',
    has_transcript: true,
    has_degree: false,
    updated_at: new Date().toISOString()
  };

  const { data: updatedProfile, error: profileError } = await supabase
    .from('student_profiles')
    .upsert(profileUpdate)
    .select()
    .single();

  if (profileError) {
    console.error('❌ Failed to update profile:', profileError);
    return;
  }
  
  console.log('✅ Profile updated successfully in Supabase!');
  console.log(JSON.stringify(updatedProfile, null, 2));
  console.log('\n-----------------------------------------------------\n');

  // STEP 2: Fetch all scholarships and match them
  console.log('🔍 STEP 2: Running Scholarship Matching Engine...');
  const { data: scholarships, error: scholError } = await supabase
    .from('scholarships')
    .select('*');

  if (scholError) {
    console.error('❌ Failed to fetch scholarships:', scholError);
    return;
  }

  // Filter scholarships based on Riffaqat's profile
  const matched = scholarships.filter(s => {
    // CGPA check
    const minCgpa = parseFloat(s.min_cgpa || '0');
    const isCgpaEligible = updatedProfile.cgpa >= minCgpa;
    
    // Degree compatibility (case-insensitive checks)
    const reqDegree = (s.required_degree || '').toLowerCase();
    const isDegreeCompatible = reqDegree.includes('bachelor') || reqDegree.includes('undergraduate') || reqDegree === 'any';

    return isCgpaEligible && isDegreeCompatible;
  });

  console.log(`✅ Found ${matched.length} Matched Scholarships for Riffaqat Hussain!\n`);
  
  matched.forEach((s, idx) => {
    console.log(`   [${idx + 1}] ${s.name} (${s.country})`);
    console.log(`       - Min CGPA: ${s.min_cgpa} | Required Degree: ${s.required_degree}`);
    console.log(`       - Required Docs: ${s.required_documents.join(', ')}`);
  });
  console.log('\n-----------------------------------------------------\n');

  if (matched.length === 0) {
    console.log('⚠️ No scholarships matched. Skipping AI Matcher agent.');
    return;
  }

  // STEP 3: Run the AI Agent for the first matched scholarship
  const targetScholarship = matched[0];
  console.log(`🤖 STEP 3: Executing Action Sim Agent for: "${targetScholarship.name}"...`);
  console.log('           (Sending profile + scholarship rules to OpenAI gpt-4o-mini)');

  // We mock having domicile=true in memory as requested
  const missingDocs = targetScholarship.required_documents.filter(doc => {
    const d = doc.toLowerCase();
    if (d.includes('transcript') && updatedProfile.has_transcript) return false;
    if (d.includes('domicile')) return false; // Mocked as available
    return true; 
  });

  const systemPrompt = `You are the Action Execution Agent (ACTOR) for Wazifa AI.
Your job is to generate real, high-quality, academic-toned application artifacts.
You must output a single, raw JSON object (no markdown formatting, no backticks) structured exactly like this:
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
    "description": "Calculated milestone deadlines based on required docs."
  },
  "sopIntro": "Statement of purpose opening paragraph (academic, professional tone) starting with 'As a dedicated graduate in...'"
}`;

  const userPrompt = `Student Profile:
- Name: ${updatedProfile.name}
- University: ${updatedProfile.university}
- CGPA: ${updatedProfile.cgpa}
- Field: ${updatedProfile.field_of_study}
- Degree: ${updatedProfile.degree_level}

Scholarship:
- Name: ${targetScholarship.name}
- Country: ${targetScholarship.country}
- Deadline: ${targetScholarship.deadline}
- Required Documents: ${JSON.stringify(targetScholarship.required_documents)}
- Missing Documents: ${JSON.stringify(missingDocs)}`;

  try {
    const response = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt }
      ],
      temperature: 0.2,
    });

    let content = response.choices[0]?.message?.content || '';
    content = content.replace(/```json/g, '').replace(/```/g, '').trim();

    const parsedAgentResult = JSON.parse(content);
    console.log('✅ AI AGENT RUN SUCCESSFUL!\n');
    console.log('=====================================================');
    console.log('📋 GENERATED ARTIFACTS:');
    console.log('=====================================================');
    console.log('\n1. 📑 SIMULATED APPLICATION FORM:');
    console.log(JSON.stringify(parsedAgentResult.simulatedForm, null, 2));
    
    console.log('\n2. 📧 PROFESSOR RECOMMENDATION EMAIL:');
    console.log('-----------------------------------------------------');
    console.log(parsedAgentResult.professorEmail);
    console.log('-----------------------------------------------------');
    
    console.log('\n3. 📅 CALENDAR ACTION MILESTONES:');
    console.log(JSON.stringify(parsedAgentResult.calendarEvent, null, 2));
    
    console.log('\n4. ✍️ STATEMENT OF PURPOSE (SOP) INTRODUCTIONS:');
    console.log('-----------------------------------------------------');
    console.log(parsedAgentResult.sopIntro);
    console.log('-----------------------------------------------------\n');
  } catch (error) {
    console.error('❌ AI Agent Execution failed:', error.message);
  }
}

runTestPipeline();
