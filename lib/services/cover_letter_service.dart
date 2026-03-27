import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cover_letter_data.dart';

class CoverLetterService {
  static const String _coverLetterKey = 'coverLetter';
  static const String _providerKey = 'coverLetterProvider';
  static const String _apiKeyKey = 'apiKey';
  static const String _customInstructionsKey = 'customInstructions';

  static Future<CoverLetterData> loadCoverLetterData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = CoverLetterData();
    data.coverLetterController.text = prefs.getString(_coverLetterKey) ?? '';
    data.selectedProvider = prefs.getString(_providerKey) ?? 'basic';
    data.apiKey = prefs.getString(_apiKeyKey) ?? '';
    data.customInstructions = prefs.getString(_customInstructionsKey) ?? '';
    return data;
  }

  static Future<void> saveCoverLetterData(CoverLetterData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_coverLetterKey, data.coverLetterController.text);
    await prefs.setString(_providerKey, data.selectedProvider);
    await prefs.setString(_apiKeyKey, data.apiKey);
    await prefs.setString(_customInstructionsKey, data.customInstructions);
  }

  static Future<String> generateCoverLetter({
    required String provider,
    required String jobTitle,
    required String company,
    required String requirements,
    required String experience,
    String apiKey = '',
    String customInstructions = '',
    String jobDescription = '',
    String firstName = '',
    String lastName = '',
    String email = '',
    String phone = '',
    List<String> skills = const [],
    List<Map<String, dynamic>> workExperience = const [],
    List<Map<String, dynamic>> education = const [],
  }) async {
    // Simulate network request
    await Future.delayed(const Duration(seconds: 2));

    switch (provider) {
      case 'basic':
        return _generateBasicCoverLetter(
          jobTitle: jobTitle,
          company: company,
          requirements: requirements,
          experience: experience,
          customInstructions: customInstructions,
          jobDescription: jobDescription,
          firstName: firstName,
          lastName: lastName,
          email: email,
          phone: phone,
          skills: skills,
          workExperience: workExperience,
          education: education,
        );
      
      case 'openai':
        if (apiKey.isEmpty) {
          return 'Error: OpenAI API key is required. Please add your API key in the settings.';
        }
        return _generateOpenAICoverLetter(apiKey, jobTitle, company, requirements, experience, customInstructions);
      
      case 'claude':
        if (apiKey.isEmpty) {
          return 'Error: Claude API key is required. Please add your API key in the settings.';
        }
        return _generateClaudeCoverLetter(apiKey, jobTitle, company, requirements, experience, customInstructions);
      
      case 'custom':
        if (apiKey.isEmpty) {
          return 'Error: Custom API endpoint and key are required.';
        }
        return _generateCustomCoverLetter(apiKey, jobTitle, company, requirements, experience, customInstructions);
      
      default:
        return 'Provider not found.';
    }
  }

  static String _generateBasicCoverLetter({
    required String jobTitle,
    required String company,
    required String requirements,
    required String experience,
    required String customInstructions,
    required String jobDescription,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required List<String> skills,
    required List<Map<String, dynamic>> workExperience,
    required List<Map<String, dynamic>> education,
  }) {
    // Basic AI that generates a professional cover letter without external APIs
    final buffer = StringBuffer();
    
    final positionText = jobTitle.isNotEmpty ? 'the $jobTitle position' : 'this opportunity';
    buffer.writeln('I am writing to express my strong interest in $positionText${company.isNotEmpty ? " at $company" : ""}. ');
    buffer.writeln('With my background and qualifications, I believe I would be a valuable addition to your team.');
    buffer.writeln();

    // Skills section
    if (skills.isNotEmpty) {
      buffer.writeln('My key skills include:');
      for (final skill in skills) {
        buffer.writeln('- $skill');
      }
      buffer.writeln();
    }

    // Work experience section
    if (workExperience.isNotEmpty) {
      buffer.writeln('My relevant work experience includes:');
      for (final exp in workExperience.take(3)) {
        final title = exp['title'] ?? 'Position';
        final comp = exp['company'] ?? 'Company';
        final desc = exp['description'] ?? '';
        final period = exp['period'] ?? '';
        
        buffer.write('- $title at $comp');
        if (period.isNotEmpty) {
          buffer.write(' ($period)');
        }
        buffer.writeln();
        
        if (desc.isNotEmpty) {
          buffer.writeln('  $desc');
        }
      }
      buffer.writeln();
    }

    // Education section
    if (education.isNotEmpty) {
      buffer.writeln('Education:');
      for (final edu in education.take(2)) {
        final degree = edu['degree'] ?? 'Degree';
        final inst = edu['institution'] ?? 'Institution';
        buffer.writeln('- $degree - $inst');
      }
      buffer.writeln();
    }

    // Job description analysis
    if (jobDescription.isNotEmpty) {
      buffer.writeln('Based on the job description provided, I can contribute by:');
      buffer.writeln('- Addressing the key responsibilities and requirements');
      buffer.writeln('- Leveraging my relevant experience and skills');
      buffer.writeln('- Bringing proven success in similar challenges');
      buffer.writeln();
    }

    // Requirements matching
    if (requirements.isNotEmpty) {
      buffer.writeln('I possess the following qualifications that match your requirements:');
      final reqList = requirements.split('\n').where((r) => r.trim().isNotEmpty);
      for (final req in reqList) {
        buffer.writeln('- $req');
      }
      buffer.writeln();
    }

    // Experience section
    if (experience.isNotEmpty) {
      buffer.writeln('My experience demonstrates:');
      buffer.writeln(experience);
      buffer.writeln();
    }

    // Closing
    buffer.writeln('I am excited about the opportunity to bring my expertise to your organization ');
    buffer.writeln('and contribute to your continued success. I would welcome the chance to discuss ');
    buffer.writeln('how my skills and experience align with your needs.');
    buffer.writeln();
    buffer.writeln('Thank you for your time and consideration.');
    buffer.writeln();
    
    if (customInstructions.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln('Additional Notes:');
      buffer.writeln(customInstructions);
    }
    
    return buffer.toString();
  }

  static String _buildPrompt(
    String jobTitle,
    String company,
    String requirements,
    String experience,
    String customInstructions,
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln('Write a professional cover letter for the following position:');
    buffer.writeln();
    
    if (jobTitle.isNotEmpty) {
      buffer.writeln('Position: $jobTitle');
    }
    if (company.isNotEmpty) {
      buffer.writeln('Company: $company');
    }
    buffer.writeln();
    
    if (requirements.isNotEmpty) {
      buffer.writeln('Key Requirements:');
      buffer.writeln(requirements);
      buffer.writeln();
    }
    
    if (experience.isNotEmpty) {
      buffer.writeln('My Relevant Experience:');
      buffer.writeln(experience);
      buffer.writeln();
    }
    
    if (customInstructions.isNotEmpty) {
      buffer.writeln('Additional Instructions:');
      buffer.writeln(customInstructions);
      buffer.writeln();
    }
    
    buffer.writeln('Please write a compelling, professional cover letter that highlights my qualifications and enthusiasm for this position. Use proper business letter format with appropriate salutation and closing.');
    
    return buffer.toString();
  }

  static Future<String> _generateOpenAICoverLetter(
    String apiKey,
    String jobTitle,
    String company,
    String requirements,
    String experience,
    String customInstructions,
  ) async {
    try {
      final prompt = _buildPrompt(jobTitle, company, requirements, experience, customInstructions);
      
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a professional cover letter writer. Write a compelling, professional cover letter based on the provided information. Make it personalized and specific to the job requirements. Use proper business letter format.'
            },
            {
              'role': 'user',
              'content': prompt
            }
          ],
          'max_tokens': 800,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        return 'Error: OpenAI API returned status ${response.statusCode}. ${response.body}';
      }
    } catch (e) {
      return 'Error calling OpenAI API: $e';
    }
  }

  static Future<String> _generateClaudeCoverLetter(
    String apiKey,
    String jobTitle,
    String company,
    String requirements,
    String experience,
    String customInstructions,
  ) async {
    try {
      final prompt = _buildPrompt(jobTitle, company, requirements, experience, customInstructions);
      
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-haiku-20240307',
          'messages': [
            {
              'role': 'user',
              'content': prompt
            }
          ],
          'max_tokens': 800,
          'temperature': 0.7,
          'system': 'You are a professional cover letter writer. Write a compelling, professional cover letter based on the provided information. Make it personalized and specific to the job requirements. Use proper business letter format.'
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'].trim();
      } else {
        return 'Error: Claude API returned status ${response.statusCode}. ${response.body}';
      }
    } catch (e) {
      return 'Error calling Claude API: $e';
    }
  }

  static Future<String> _generateCustomCoverLetter(
    String apiKey,
    String jobTitle,
    String company,
    String requirements,
    String experience,
    String customInstructions,
  ) async {
    try {
      // For custom endpoints, we'll use the apiKey as the endpoint URL
      // Format: "https://your-api.com/generate|your-api-key"
      final parts = apiKey.split('|');
      if (parts.length != 2) {
        return 'Error: Custom API key must be in format "endpoint|key". Example: "https://your-api.com/generate|your-api-key"';
      }
      
      final endpoint = parts[0];
      final key = parts[1];
      
      final prompt = _buildPrompt(jobTitle, company, requirements, experience, customInstructions);
      
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $key',
        },
        body: jsonEncode({
          'jobTitle': jobTitle,
          'company': company,
          'requirements': requirements,
          'experience': experience,
          'customInstructions': customInstructions,
          'prompt': prompt,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Support different response formats
        if (data['coverLetter'] != null) {
          return data['coverLetter'];
        } else if (data['content'] != null) {
          return data['content'];
        } else if (data['text'] != null) {
          return data['text'];
        } else if (data['choices'] != null && data['choices'][0]['message'] != null) {
          return data['choices'][0]['message']['content'];
        } else {
          return response.body;
        }
      } else {
        return 'Error: Custom API returned status ${response.statusCode}. ${response.body}';
      }
    } catch (e) {
      return 'Error calling custom API: $e';
    }
  }

  static List<String> getAvailableProviders() {
    return [
      'basic',
      'openai',
      'claude',
      'custom',
    ];
  }

  static String getProviderDisplayName(String provider) {
    switch (provider) {
      case 'basic':
        return 'Basic AI (Free)';
      case 'openai':
        return 'OpenAI (GPT)';
      case 'claude':
        return 'Claude (Anthropic)';
      case 'custom':
        return 'Custom AI';
      default:
        return provider;
    }
  }

  static String getProviderDescription(String provider) {
    switch (provider) {
      case 'basic':
        return 'Free AI-powered cover letter generator using built-in templates';
      case 'openai':
        return 'Use OpenAI GPT for advanced cover letter generation (API key required)';
      case 'claude':
        return 'Use Claude AI for sophisticated cover letter writing (API key required)';
      case 'custom':
        return 'Connect to your own AI endpoint (API configuration required)';
      default:
        return 'Unknown provider';
    }
  }
}
