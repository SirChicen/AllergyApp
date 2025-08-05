# AllergyApp: Complete Development Plan

## 🎯 **Project Overview**

AllergyApp is a mobile application that helps users with food allergies safely navigate restaurant menus by using OCR (Optical Character Recognition) and AI analysis to identify potential allergens and provide safety ratings.

### **Core Features**
- **Allergen Profile Management**: Support for all 11 major allergens (peanuts, tree nuts, sesame, milk, egg, fish, shellfish, soy, wheat, mustard, sulphites)
- **Menu Photo Capture**: Camera integration for taking photos of restaurant menus
- **OCR Text Extraction**: Convert menu images to readable text
- **AI-Powered Analysis**: LLM analysis of menu items for allergen detection
- **Safety Ratings**: Color-coded system (🟢 Safe, 🟡 Caution, 🔴 Avoid)
- **Follow-up Questions**: AI-generated queries for ambiguous items

## 🛠️ **Technology Stack**

### **Mobile Framework**: Flutter
- Single codebase for iOS and Android
- Excellent camera integration and image processing capabilities
- Strong OCR library support

### **OCR Solution**: Google Vision API
- High accuracy (98%+ for clear text)
- Excellent handling of various fonts and menu styles
- Cost: $1.50 per 1,000 pages processed

### **AI/LLM Integration**: OpenAI GPT-4o
- Advanced reasoning capabilities for ingredient analysis
- Cost: ~$0.01-0.06 per 1K tokens
- Conservative prompting strategy to minimize false negatives

### **Database**: SQLite (Local Storage)
- Store user allergen profiles locally
- Cache analysis results
- No cloud storage for privacy

### **Architecture**: MVVM + Clean Architecture
- Presentation Layer (UI/Views)
- Business Logic (Use Cases/Interactors) 
- Data Layer (Repository Pattern)
- External Services (Camera, OCR, AI)

## 📱 **User Experience Flow**

1. **First Launch**: User selects their allergies from the 11 major allergens
2. **Menu Scanning**: User takes photo of restaurant menu
3. **Processing**: App extracts text via OCR and analyzes with AI
4. **Results**: Display color-coded safety ratings for each menu item
5. **Details**: Show reasoning and suggested follow-up questions
6. **Continuous Use**: App remembers user preferences for future sessions

## ⚖️ **Legal & Safety Strategy**

### **Positioning**: Informational Tool Only
- Clear disclaimers that app is for informational purposes
- Encourage users to verify with restaurant staff
- No medical advice or treatment recommendations
- Avoid FDA medical device classification

### **Safety Approach**: Conservative Analysis
- Prioritize accuracy over speed
- Err on side of caution (higher false positives acceptable)
- Target <1% false negative rate
- Clear confidence scoring for uncertain items

## 🏗️ **MVP Development Plan (8-12 weeks)**

The MVP will focus on core functionality with the following features:

### **Core MVP Features**
1. **User Onboarding & Profile Setup**
   - Allergen selection from 11 major allergens
   - Local storage of user preferences

2. **Camera Integration**
   - Photo capture functionality
   - Basic image optimization

3. **OCR Processing**
   - Google Vision API integration
   - Text extraction from menu images

4. **AI Analysis**
   - OpenAI GPT-4o integration
   - Allergen detection and safety rating
   - Conservative prompting strategy

5. **Results Display**
   - Color-coded safety ratings
   - Basic reasoning explanation
   - Confidence scores

6. **Core UI/UX**
   - Clean, accessible interface
   - Intuitive navigation
   - Clear safety indicators

### **MVP Limitations**
- Internet connection required
- English language only
- No offline functionality
- No advanced image preprocessing
- No follow-up questions generation
- No accessibility features

## 💰 **Cost Considerations**

### **Development Costs**
- Personal project with Claude Code (no team costs)
- Primary costs: API usage for OCR and AI analysis

### **Operational Costs (Estimated Monthly)**
- Google Vision API: ~$15-50 depending on usage
- OpenAI API: ~$20-100 depending on analysis complexity
- Total: ~$35-150/month for moderate usage

### **Cost Optimization**
- Implement caching for repeated menu items
- Optimize image quality before OCR processing
- Efficient AI prompting to minimize token usage

## 🔒 **Privacy & Data Handling**

### **Data Storage**
- All user data stored locally on device
- No cloud storage or user accounts required
- Allergen profiles persist between app sessions

### **Data Collection**
- Only collect user's selected allergies
- No personal information required
- No analytics or usage tracking in MVP

## 🧪 **Testing Strategy**

### **MVP Testing Focus**
1. **OCR Accuracy**: Test with various restaurant menu styles
2. **AI Analysis**: Validate allergen detection across different cuisines
3. **False Negative Monitoring**: Ensure safety-critical accuracy
4. **User Interface**: Basic usability testing
5. **Device Compatibility**: Test on various iOS/Android devices

## 🚀 **Post-MVP Enhancements**

Future phases could include:
- Offline functionality with local OCR
- Multi-language support
- Advanced image preprocessing
- Follow-up questions generation
- Accessibility features
- Community features and crowd-sourced data
- Restaurant integration APIs

## 📋 **Success Metrics**

### **MVP Success Criteria**
- OCR accuracy: >90% for clear menu text
- AI analysis accuracy: <1% false negative rate
- User can complete full workflow (photo → results) in <60 seconds
- App successfully handles at least 80% of common restaurant menu formats

---

## 📞 **Project Context**

- **Scope**: Personal project using Claude Code
- **Timeline**: 8-12 weeks for MVP
- **Budget**: API costs only (~$35-150/month)
- **Monetization**: None planned
- **Target Users**: Individuals with food allergies
- **Geographic Focus**: None (English language initially)
- **Regulatory**: Informational tool only, no medical device classification