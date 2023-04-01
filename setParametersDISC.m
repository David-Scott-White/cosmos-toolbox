classdef setParametersDISC < handle
    % GUI popup to set DISC idealization parameters -----------------------
    
    
    
    properties (Access=private)
        
        hParent
        hCheckBoxAutoDISC
        hCheckBoxAutoDISCText
        hEditAlpha
        hEditAlphaText
        hPopupDivisive
        hPopupDivisiveText
        hPopupAgglomerative
        hPopupAgglomerativeText
        hCheckBoxViterbi
        hCheckBoxViterbiText
        hEditReturnK
        hEditReturnKText
        hApplySettingsButton
        
    end
    
    properties (SetObservable)
        autoDISC
        alpha
        divisive
        agglomerative
        viterbi
        return_k
    end
    
    methods
        % constructor -----------------------------------------------------
        function obj = setParametersDISC(param)
            if nargin < 1
                obj.autoDISC = 0;
                obj.alpha = 0.05;
                obj.divisive = 'BIC_GMM';
                obj.agglomerative = 'BIC_GMM';
                obj.viterbi = 1;
                obj.return_k = NaN;
            else
                obj.autoDISC =  param.autoDISC;
                obj.autoDISC = param.autoDISC;
                obj.alpha = param.alpha;
                obj.divisive = param.divisive;
                obj.agglomerative = param.agglomerative;
                obj.viterbi =  param.viterbi;
                obj.return_k = param.return_k;
            end
            
            % delete any open windows
             delete(findobj('Name', 'Set DISC Param'));
             
             margin = 5; 
             lineh = 20; 
             width = 240; 
             height = 150; 
             
             set(0,'units','pixels') ;
             screen_pixels = get(0,'screensize');
             x = screen_pixels(3)/2-width/2;
             y = screen_pixels(4)/2-height/2;
             
             % Create items with values
             obj.hParent = figure(...
                 'Name', 'Set DISC Param',...
                 'Visible', 'on',...
                 'Units', 'pixels',...
                 'MenuBar', 'None',...
                 'resize','off', ...
                 'NumberTitle', 'off',...
                 'Position', [x, y, width, height]);
             
             W = (width-margin-lineh)/2;
             x1 = margin;
             x2 = margin + W;
             
             y1 = height-lineh-margin;
             obj.hEditAlphaText = uicontrol(obj.hParent,...
                 'Style', 'Text', ...
                 'String', 'Alpha',...
                 'Units', 'Pixels',...
                 'Position', [x1, y1, W, lineh]);
             obj.hEditAlpha = uicontrol(obj.hParent,...
                 'Style', 'Edit', ...
                 'Units', 'Pixels',...
                 'String', {'0.05'},...
                 'Position', [x2, y1, W, lineh]);
             
             y1 = y1 -lineh;
             obj.hPopupDivisiveText = uicontrol(obj.hParent,...
                 'Style', 'Text', ...
                 'String', 'Divisive IC',...
                 'Position', [x1, y1, W, lineh]);
             obj.hPopupDivisive = uicontrol(obj.hParent,...
                 'Style', 'popupmenu', ...
                 'String', {'BIC_GMM', 'AIC_GMM', 'BIC_RSS', 'none'},...
                 'Position', [x2, y1, W, lineh]);
             
             y1 = y1 -lineh;
            obj.hPopupAgglomerativeText = uicontrol(obj.hParent,...
                'Style', 'Text', ...
                 'String', 'Agglomerative IC',...
                 'Position', [x1, y1, W, lineh]);
             obj.hPopupAgglomerative = uicontrol(obj.hParent,...
                 'Style', 'popupmenu', ...
                 'String', {'BIC_GMM', 'AIC_GMM', 'BIC_RSS', 'none'},...
                 'Position', [x2, y1, W, lineh]);
             
             y1 = y1 -lineh;
             obj.hCheckBoxViterbiText = uicontrol(obj.hParent,...
                 'Style', 'Text', ...
                 'String', 'Viterbi',...
                 'Position', [x1, y1, W, lineh]);
             obj.hCheckBoxViterbi = uicontrol(obj.hParent,...
                 'Style', 'checkbox', ...
                 'String', '',...
                 'Value', 1,...
                 'Position', [x2, y1, W, lineh]);
             
             y1 = y1-lineh;
             obj.hEditReturnKText = uicontrol(obj.hParent,...
                 'Style', 'Text', ...
                 'String', 'Return K States',...
                 'Position', [x1, y1, W, lineh]);
             obj.hEditReturnK = uicontrol(obj.hParent,...
                 'Style', 'Edit', ...
                 'String', {'NaN'},...
                 'Position', [x2, y1, W, lineh]);
             
             % center position 
             y1 = y1-lineh-margin;
             obj.hApplySettingsButton = uicontrol(obj.hParent,...
                 'Style', 'PushButton',...
                 'String', 'Apply Settings', ...
                 'Visible', 'on', ...
                 'Callback',@(src,event)applySettings(obj),...
                 'Position', [x1+W/2+margin, y1, W, lineh]);
             
        end
        
        function applySettings(obj)
            % obj.autoDISC = 0;
            obj.alpha = str2double(obj.hEditAlpha.String);
            obj.divisive = obj.hPopupDivisive.String{obj.hPopupDivisive.Value};
            obj.agglomerative = obj.hPopupAgglomerative.String{obj.hPopupAgglomerative.Value};
            obj.viterbi = obj.hCheckBoxViterbi.Value;
            obj.return_k = str2double(obj.hEditReturnK.String);
        end
        
        function delete(obj)
            delete(obj.hParent);
        end
    end
end