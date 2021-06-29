module Debugger
  class DBGP_FeatureGet < Command # :nodoc:
    self.cmd_name = :feature_get

    def execute(processor, cmdArgs)
      featureName = cmdArgs.getArg('-n');
      innerText = nil;
      if featureName.nil?
        featureName = "unspecified";
        supported = 0;
      elsif processor.supportedCommands.has_key?(featureName)
        supported = processor.supportedCommands[featureName];
      elsif processor.supportedFeatures.has_key?(featureName)
        vals = processor.supportedFeatures[featureName]
        supported = vals[0]
        if vals[2] == 0 || !processor.settings.has_key?(featureName)
          innerText = nil;
        else
          innerText = processor.settings[featureName][0];
        end
      else
        # Command not recognized
        supported = 0;
      end
      processor.complete_response_print({:feature_name => featureName,
                                          :supported => supported}, innerText)
    end
  end
  class DBGP_FeatureSet < Command # :nodoc:
    self.cmd_name = :feature_set

    def execute(processor, cmdArgs)
      featureName, featureValue = cmdArgs.pickArgs("n:v:")
      reason = nil
      status = 0
      if featureName.nil?
        success = 0;
        reason = "Command not specified";
      elsif !processor.supportedFeatures.has_key?(featureName)
        status = 0;
        reason = "Command #{featureName} not recognized";
      else
        vals = processor.supportedFeatures[featureName]
        if vals[1] == 0
          status = 0;
          reason = "Command #{featureName} not modifiable";
        elsif vals[2] == 0
          # No associated data, use boolean value in table
          vals[0] = featureValue ? 1 : 0;
          status = 1;
          success = vals[0];
        elsif !processor.settings.has_key?(featureName)
          status = 0;
          reason = "Command #{featureName} not in settings table";
        else
          svals = processor.settings[featureName][1];
          if (svals.nil?)
            status = 0;
            reason ="Command #{featureName} is readonly settings table";
          elsif svals.class == Array
            status = 0;
            svals.each {|allowedValue|
              if featureValue == allowedValue
                status = 1;
                processor.settings[featureName][0] = featureValue;
                if status == 1 && featureName == 'data_encoding'
                  processor.propInfo.default_encoding = featureValue
                  processor.stdout.default_encoding = featureValue if processor.stdout
                  processor.stderr.default_encoding = featureValue if processor.stderr
                end
                break
              end
            }
            if status == 0
              reason = "Command #{featureName} value of #{featureValue} isn't an allowed value.";
            end
          elsif svals == 1
            # Hardwire numeric values
            if featureValue =~ /^\d+/
              status = 1;
              processor.settings[featureName][0] = featureValue.to_i;
            else
              status = 0;
              reason = "Command #{featureName} value of #{featureValue} isn't numeric.";
            end
          elsif svals == 'a'
            # Allow any ascii data
            status = 1;
            processor.settings[featureName][0] = featureValue;
          else
            status = 0;
            reason = "Command #{featureName}=#{featureValue}, can't deal with current setting of " + pp(vals) + "\n";
          end
        end
      end
      
      attrs = {
        :feature_name => featureName,
        :success => status}
      attrs[:reason] = reason if reason
      processor.complete_response_print(attrs)
    end
  end
end
