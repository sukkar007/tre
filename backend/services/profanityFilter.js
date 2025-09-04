const fs = require('fs');
const path = require('path');

/**
 * خدمة فلتر الكلمات السيئة والمحتوى غير المناسب
 * تدعم اللغة العربية والإنجليزية مع إعدادات قابلة للتخصيص
 */
class ProfanityFilter {
  constructor() {
    this.arabicBadWords = [];
    this.englishBadWords = [];
    this.customBadWords = [];
    this.whitelist = [];
    this.severity = {
      LOW: 1,
      MEDIUM: 2,
      HIGH: 3,
      EXTREME: 4
    };
    this.filterLevel = this.severity.MEDIUM;
    this.replacementChar = '*';
    this.loadBadWords();
  }

  /**
   * تحميل قوائم الكلمات السيئة
   */
  loadBadWords() {
    // كلمات عربية سيئة (مصنفة حسب الشدة)
    this.arabicBadWords = {
      [this.severity.LOW]: [
        'غبي', 'أحمق', 'مجنون', 'سخيف', 'تافه'
      ],
      [this.severity.MEDIUM]: [
        'لعين', 'حقير', 'وسخ', 'قذر', 'منحط',
        'خنزير', 'كلب', 'حمار', 'بقرة'
      ],
      [this.severity.HIGH]: [
        'ابن كلب', 'ابن حرام', 'يا كلب', 'يا حمار',
        'عاهرة', 'قحبة', 'شرموطة', 'زانية'
      ],
      [this.severity.EXTREME]: [
        'كس امك', 'ابن الشرموطة', 'ابن القحبة',
        'نيك', 'زب', 'طيز', 'كس'
      ]
    };

    // كلمات إنجليزية سيئة (مصنفة حسب الشدة)
    this.englishBadWords = {
      [this.severity.LOW]: [
        'stupid', 'idiot', 'dumb', 'fool', 'moron'
      ],
      [this.severity.MEDIUM]: [
        'damn', 'hell', 'crap', 'suck', 'hate',
        'loser', 'jerk', 'freak'
      ],
      [this.severity.HIGH]: [
        'bitch', 'bastard', 'asshole', 'dickhead',
        'motherfucker', 'son of a bitch'
      ],
      [this.severity.EXTREME]: [
        'fuck', 'shit', 'pussy', 'dick', 'cock',
        'whore', 'slut', 'nigger', 'faggot'
      ]
    };

    // كلمات مخصصة يمكن إضافتها
    this.customBadWords = [];

    // قائمة بيضاء للكلمات المستثناة
    this.whitelist = [
      'class', 'classic', 'glass', 'grass', // تحتوي على 'ass' لكنها ليست سيئة
      'scunthorpe', 'penistone', // أسماء أماكن
      'arsenal', 'assassin' // كلمات عادية
    ];
  }

  /**
   * تحديد مستوى الفلترة
   * @param {number} level - مستوى الفلترة (1-4)
   */
  setFilterLevel(level) {
    if (level >= this.severity.LOW && level <= this.severity.EXTREME) {
      this.filterLevel = level;
    }
  }

  /**
   * إضافة كلمة مخصصة للقائمة السوداء
   * @param {string} word - الكلمة المراد إضافتها
   * @param {number} severity - شدة الكلمة
   */
  addCustomBadWord(word, severity = this.severity.MEDIUM) {
    if (!this.customBadWords[severity]) {
      this.customBadWords[severity] = [];
    }
    this.customBadWords[severity].push(word.toLowerCase());
  }

  /**
   * إضافة كلمة للقائمة البيضاء
   * @param {string} word - الكلمة المراد استثناؤها
   */
  addToWhitelist(word) {
    this.whitelist.push(word.toLowerCase());
  }

  /**
   * الحصول على جميع الكلمات السيئة حسب مستوى الفلترة
   * @returns {Array} قائمة الكلمات السيئة
   */
  getAllBadWords() {
    let allBadWords = [];
    
    // إضافة الكلمات العربية
    for (let level = this.severity.LOW; level <= this.filterLevel; level++) {
      if (this.arabicBadWords[level]) {
        allBadWords = allBadWords.concat(this.arabicBadWords[level]);
      }
    }
    
    // إضافة الكلمات الإنجليزية
    for (let level = this.severity.LOW; level <= this.filterLevel; level++) {
      if (this.englishBadWords[level]) {
        allBadWords = allBadWords.concat(this.englishBadWords[level]);
      }
    }
    
    // إضافة الكلمات المخصصة
    for (let level = this.severity.LOW; level <= this.filterLevel; level++) {
      if (this.customBadWords[level]) {
        allBadWords = allBadWords.concat(this.customBadWords[level]);
      }
    }
    
    return allBadWords.map(word => word.toLowerCase());
  }

  /**
   * فحص النص للكلمات السيئة
   * @param {string} text - النص المراد فحصه
   * @returns {Object} نتيجة الفحص
   */
  checkText(text) {
    if (!text || typeof text !== 'string') {
      return {
        isClean: true,
        foundWords: [],
        severity: 0,
        filteredText: text
      };
    }

    const originalText = text;
    const lowerText = text.toLowerCase();
    const badWords = this.getAllBadWords();
    const foundWords = [];
    let maxSeverity = 0;
    let filteredText = text;

    // فحص كل كلمة سيئة
    badWords.forEach(badWord => {
      const regex = new RegExp(`\\b${this.escapeRegex(badWord)}\\b`, 'gi');
      
      if (regex.test(lowerText)) {
        // التحقق من القائمة البيضاء
        const isWhitelisted = this.whitelist.some(whiteWord => 
          lowerText.includes(whiteWord.toLowerCase())
        );
        
        if (!isWhitelisted) {
          foundWords.push(badWord);
          
          // تحديد شدة الكلمة
          const wordSeverity = this.getWordSeverity(badWord);
          maxSeverity = Math.max(maxSeverity, wordSeverity);
          
          // استبدال الكلمة
          const replacement = this.replacementChar.repeat(badWord.length);
          filteredText = filteredText.replace(regex, replacement);
        }
      }
    });

    // فحص الأنماط المشبوهة
    const suspiciousPatterns = this.checkSuspiciousPatterns(lowerText);
    if (suspiciousPatterns.length > 0) {
      foundWords.push(...suspiciousPatterns);
      maxSeverity = Math.max(maxSeverity, this.severity.MEDIUM);
    }

    return {
      isClean: foundWords.length === 0,
      foundWords: [...new Set(foundWords)], // إزالة التكرار
      severity: maxSeverity,
      filteredText: filteredText,
      originalText: originalText
    };
  }

  /**
   * تحديد شدة الكلمة
   * @param {string} word - الكلمة
   * @returns {number} مستوى الشدة
   */
  getWordSeverity(word) {
    const lowerWord = word.toLowerCase();
    
    // فحص الكلمات العربية
    for (let level = this.severity.EXTREME; level >= this.severity.LOW; level--) {
      if (this.arabicBadWords[level] && 
          this.arabicBadWords[level].includes(lowerWord)) {
        return level;
      }
    }
    
    // فحص الكلمات الإنجليزية
    for (let level = this.severity.EXTREME; level >= this.severity.LOW; level--) {
      if (this.englishBadWords[level] && 
          this.englishBadWords[level].includes(lowerWord)) {
        return level;
      }
    }
    
    // فحص الكلمات المخصصة
    for (let level = this.severity.EXTREME; level >= this.severity.LOW; level--) {
      if (this.customBadWords[level] && 
          this.customBadWords[level].includes(lowerWord)) {
        return level;
      }
    }
    
    return this.severity.LOW;
  }

  /**
   * فحص الأنماط المشبوهة (مثل الكلمات المقسمة بأحرف أو أرقام)
   * @param {string} text - النص
   * @returns {Array} قائمة الأنماط المشبوهة
   */
  checkSuspiciousPatterns(text) {
    const suspiciousPatterns = [];
    
    // أنماط الكلمات المقسمة بأحرف خاصة
    const separatorPatterns = [
      /f[\s\-_\.]*u[\s\-_\.]*c[\s\-_\.]*k/gi,
      /s[\s\-_\.]*h[\s\-_\.]*i[\s\-_\.]*t/gi,
      /b[\s\-_\.]*i[\s\-_\.]*t[\s\-_\.]*c[\s\-_\.]*h/gi,
      /ك[\s\-_\.]*س[\s\-_\.]*ا[\s\-_\.]*م[\s\-_\.]*ك/gi,
      /ا[\s\-_\.]*ب[\s\-_\.]*ن[\s\-_\.]*ك[\s\-_\.]*ل[\s\-_\.]*ب/gi
    ];
    
    separatorPatterns.forEach(pattern => {
      const matches = text.match(pattern);
      if (matches) {
        suspiciousPatterns.push(...matches);
      }
    });
    
    // أنماط الكلمات المكتوبة بأرقام
    const leetSpeakPatterns = [
      { pattern: /f4ck|fu(k|ck)/gi, word: 'fuck' },
      { pattern: /5h1t|sh17/gi, word: 'shit' },
      { pattern: /b17ch|b!tch/gi, word: 'bitch' },
      { pattern: /4ss|@ss/gi, word: 'ass' }
    ];
    
    leetSpeakPatterns.forEach(({ pattern, word }) => {
      if (pattern.test(text)) {
        suspiciousPatterns.push(word);
      }
    });
    
    return suspiciousPatterns;
  }

  /**
   * تنظيف النص من الكلمات السيئة
   * @param {string} text - النص المراد تنظيفه
   * @returns {string} النص المنظف
   */
  cleanText(text) {
    const result = this.checkText(text);
    return result.filteredText;
  }

  /**
   * فحص سريع للنص
   * @param {string} text - النص المراد فحصه
   * @returns {boolean} true إذا كان النص نظيفاً
   */
  isTextClean(text) {
    const result = this.checkText(text);
    return result.isClean;
  }

  /**
   * تحديث إعدادات الفلتر
   * @param {Object} settings - الإعدادات الجديدة
   */
  updateSettings(settings) {
    if (settings.filterLevel !== undefined) {
      this.setFilterLevel(settings.filterLevel);
    }
    
    if (settings.replacementChar !== undefined) {
      this.replacementChar = settings.replacementChar;
    }
    
    if (settings.customBadWords && Array.isArray(settings.customBadWords)) {
      settings.customBadWords.forEach(({ word, severity }) => {
        this.addCustomBadWord(word, severity);
      });
    }
    
    if (settings.whitelist && Array.isArray(settings.whitelist)) {
      settings.whitelist.forEach(word => {
        this.addToWhitelist(word);
      });
    }
  }

  /**
   * الحصول على إحصائيات الفلتر
   * @returns {Object} إحصائيات الفلتر
   */
  getFilterStats() {
    const arabicWordsCount = Object.values(this.arabicBadWords)
      .reduce((total, words) => total + words.length, 0);
    
    const englishWordsCount = Object.values(this.englishBadWords)
      .reduce((total, words) => total + words.length, 0);
    
    const customWordsCount = Object.values(this.customBadWords)
      .reduce((total, words) => total + words.length, 0);
    
    return {
      totalBadWords: arabicWordsCount + englishWordsCount + customWordsCount,
      arabicWords: arabicWordsCount,
      englishWords: englishWordsCount,
      customWords: customWordsCount,
      whitelistWords: this.whitelist.length,
      currentFilterLevel: this.filterLevel,
      filterLevelName: this.getFilterLevelName(this.filterLevel)
    };
  }

  /**
   * الحصول على اسم مستوى الفلترة
   * @param {number} level - مستوى الفلترة
   * @returns {string} اسم المستوى
   */
  getFilterLevelName(level) {
    switch (level) {
      case this.severity.LOW: return 'منخفض';
      case this.severity.MEDIUM: return 'متوسط';
      case this.severity.HIGH: return 'عالي';
      case this.severity.EXTREME: return 'صارم جداً';
      default: return 'غير محدد';
    }
  }

  /**
   * تنظيف regex من الأحرف الخاصة
   * @param {string} string - النص
   * @returns {string} النص المنظف
   */
  escapeRegex(string) {
    return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }

  /**
   * حفظ إعدادات الفلتر في ملف
   * @param {string} filePath - مسار الملف
   */
  saveSettings(filePath) {
    const settings = {
      filterLevel: this.filterLevel,
      replacementChar: this.replacementChar,
      customBadWords: this.customBadWords,
      whitelist: this.whitelist,
      lastUpdated: new Date().toISOString()
    };
    
    try {
      fs.writeFileSync(filePath, JSON.stringify(settings, null, 2));
      return true;
    } catch (error) {
      console.error('خطأ في حفظ إعدادات الفلتر:', error);
      return false;
    }
  }

  /**
   * تحميل إعدادات الفلتر من ملف
   * @param {string} filePath - مسار الملف
   */
  loadSettings(filePath) {
    try {
      if (fs.existsSync(filePath)) {
        const settings = JSON.parse(fs.readFileSync(filePath, 'utf8'));
        this.updateSettings(settings);
        return true;
      }
    } catch (error) {
      console.error('خطأ في تحميل إعدادات الفلتر:', error);
    }
    return false;
  }

  /**
   * تصدير قائمة الكلمات السيئة
   * @returns {Object} قائمة الكلمات السيئة
   */
  exportBadWords() {
    return {
      arabic: this.arabicBadWords,
      english: this.englishBadWords,
      custom: this.customBadWords,
      whitelist: this.whitelist
    };
  }

  /**
   * استيراد قائمة كلمات سيئة
   * @param {Object} badWordsData - بيانات الكلمات السيئة
   */
  importBadWords(badWordsData) {
    if (badWordsData.arabic) {
      this.arabicBadWords = { ...this.arabicBadWords, ...badWordsData.arabic };
    }
    
    if (badWordsData.english) {
      this.englishBadWords = { ...this.englishBadWords, ...badWordsData.english };
    }
    
    if (badWordsData.custom) {
      this.customBadWords = { ...this.customBadWords, ...badWordsData.custom };
    }
    
    if (badWordsData.whitelist) {
      this.whitelist = [...this.whitelist, ...badWordsData.whitelist];
    }
  }
}

// إنشاء مثيل واحد للاستخدام العام
const profanityFilter = new ProfanityFilter();

module.exports = {
  ProfanityFilter,
  profanityFilter
};

