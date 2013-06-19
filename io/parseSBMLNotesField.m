function [varargout] = parseSBMLNotesField(notesField)

    %%TODO: figure out varargout - call was 
    %[genes, rule, subSystem, grRule, formula, confidenceScore, ...
% citation, comment, ecNumber, charge, rxnGeneMat] = ...
% parseSBMLNotesField(notesField)
    
    % parseSBMLNotesField Parse the notes field of an SBML file to extract
    % gene-rxn associations and other annotation
    %
    % [genes, rule, subSystem, grRule, formula, confidenceScore, ...
    %        citation, comment, ecNumber, charge] = ...
    %        parseSBMLNotesField(notesField)

    % Markus Herrgard 8/7/06
    % Ines Thiele 1/27/10 - Added new fields
    % Ben Heavner 18 June 2013 - add cell array functionality and
    % rxnGeneMat as optional output
    %


    if isempty(regexp(notesField,'html:p', 'once'))
        tag = 'p';
    else
        tag = 'html:p';
    end

    if ischar(notesField) %if a string, use MH's code
        
        subSystem = '';
        grRule = '';
        genes = {};
        rule = '';
        formula = '';
        confidenceScore = '';
        citation = '';
        ecNumber = '';
        comment = '';
        charge = [];
    
        [~,fieldList] = regexp(notesField,['<' tag '>.*?</' tag '>'], ...
            'tokens', 'match');

        for i = 1:length(fieldList)
            fieldTmp = regexp(fieldList{i},['<' tag '>(.*)</' tag '>'], ...
                'tokens');
            fieldStr = fieldTmp{1}{1};
            if (regexp(fieldStr,'GENE_ASSOCIATION'))
                gprStr = regexprep(strrep(fieldStr, ...
                    'GENE_ASSOCIATION:',''), '^(\s)+','');
                grRule = gprStr;
                [genes,rule] = parseBoolean(gprStr);
            elseif (regexp(fieldStr,'GENE ASSOCIATION'))
                gprStr = regexprep(strrep(fieldStr, ...
                    'GENE ASSOCIATION:',''), '^(\s)+','');
                grRule = gprStr;
                [genes,rule] = parseBoolean(gprStr);
            elseif (regexp(fieldStr,'SUBSYSTEM'))
                subSystem = regexprep(strrep(fieldStr,'SUBSYSTEM:',''), ...
                    '^(\s)+','');
                subSystem = strrep(subSystem,'S_','');
                subSystem = regexprep(subSystem,'_+',' ');
                if (isempty(subSystem))
                    subSystem = 'Exchange';
                end
            elseif (regexp(fieldStr,'EC Number'))
                ecNumber = regexprep(strrep(fieldStr,'EC Number:',''), ...
                    '^(\s)+','');
            elseif (regexp(fieldStr,'FORMULA'))
                formula = regexprep(strrep(fieldStr,'FORMULA:',''), ...
                    '^(\s)+','');
            elseif (regexp(fieldStr,'CHARGE'))
                charge = str2num(regexprep(strrep(fieldStr, ...
                    'CHARGE:',''), '^(\s)+',''));
            elseif (regexp(fieldStr,'AUTHORS'))
                if isempty(citation)
                    citation = strcat(...
                        regexprep(strrep(fieldStr,'AUTHORS:',''), ...
                        '^(\s)+',''));
                else
                    citation = strcat(...
                        citation, ';', ...
                        regexprep(strrep(fieldStr,'AUTHORS:',''), ...
                        '^(\s)+',''));
                end
            elseif Comment == 1 && isempty(regexp(fieldStr,'genes:', ...
                    'once'))
                Comment = 0;
                comment = fieldStr;
            elseif (regexp(fieldStr,'Confidence'))
                confidenceScore = regexprep(strrep(fieldStr, ...
                    'Confidence Level:', ''), '^(\s)+', '');
                Comment = 1;
            end
        end

    elseif iscell(notesField) % if a cell array, use BH code

        NotesKeys = { ...
            'GENE_ASSOCIATION' ...
            'GENE ASSOCIATION' ...
            'SUBSYSTEM' ...
            'EC Number' ...
            'AUTHORS' ...
            'Confidence Level' ...
            'FORMULA' ...
            'CHARGE' ...
            };

        grRule = regexp(notesField, ...
            ['<' tag '>' NotesKeys{1} ':.*?</' tag '>'], 'match');
        key = NotesKeys{1};

        if sum(cellfun('isempty',grRule))
            grRule = regexp(notesField, ...
                ['<' tag '>' NotesKeys{2} ':.*?</' tag '>'], 'match');
            key = NotesKeys{2};
        end

        % strip HTML open tag and key text
        grRule = cellfun(@(x) regexprep(x, ['<' tag '>' key ': '], ...
            ''), grRule, 'UniformOutput', 0); 
        
        % strip tag close tags
        grRule = cellfun(@(x) regexprep(x, ['</\' tag '>'], ''), ...
            grRule, 'UniformOutput', 0); 
        
        grRule = [grRule{:}]'; % unnest cell

        [genes, rule, rxnGeneMat] = parseBoolean(grRule);
        
        subSystem = regexp(notesField, ...
            ['<' tag '>' NotesKeys{3} ':.*?</' tag '>'], 'match');
        
        % strip HTML open tag and key text
        subSystem = cellfun(@(x) ...
            regexprep(x, ['<' tag '>' NotesKeys{3} ': '], ''), ...
            subSystem, 'UniformOutput', 0);
        
        % strip tag close tags
        subSystem = cellfun(@(x) regexprep(x, ['</\' tag '>'],''), ...
            subSystem, 'UniformOutput', 0);
        
        % added to support some legacy subsystem encoding?
         subSystem = cellfun(@(x) strrep(x,'S_',''), subSystem, ...
             'UniformOutput', 0);
         subSystem = cellfun(@(x) regexprep(x,'_+',' '), subSystem, ...
             'UniformOutput', 0);
         subSystem(cellfun('isempty',subSystem)) = {{'Exchange'}};
         subSystem = [subSystem{:}]'; % unnest cell
      
        ecNumber = regexp(notesField, ...
            ['<' tag '>' NotesKeys{4} ':.*?</' tag '>'] , 'match');
        
        % strip HTML open tag and key text
        ecNumber = cellfun(@(x) regexprep(x, ...
            ['<' tag '>' NotesKeys{4} ': '], ''), ecNumber, ...
            'UniformOutput', 0);
        
        % strip tag close tags
        ecNumber = cellfun(@(x) regexprep(x, ['</\' tag '>'], ''), ...
            ecNumber, 'UniformOutput', 0); 
        ecNumber = [ecNumber{:}]'; % unnest cell

        citation = regexp(notesField, ...
            ['<' tag '>' NotesKeys{5} ':.*?</' tag '>'] , 'match');
        
        % strip HTML open tag and key text
        citation = cellfun(@(x) regexprep(x, ...
            ['<' tag '>' NotesKeys{5} ': '], ''), citation, ...
            'UniformOutput', 0);
        
        % strip tag close tags
        citation = cellfun(@(x) regexprep(x, ['</\' tag '>'],''), ...
            citation, 'UniformOutput', 0); 
        citation = [citation{:}]'; % unnest cell

        confidenceScore = regexp(notesField, ...
            ['<' tag '>' NotesKeys{6} ':.*?</' tag '>'] , 'match');
        
        % strip HTML open tag and key text
        confidenceScore = cellfun(@(x) regexprep(x, ...
            ['<' tag '>' NotesKeys{6} ': '], ''), confidenceScore, ...
            'UniformOutput', 0);
        
        % strip tag close tags
        confidenceScore = cellfun(@(x) regexprep(x, ...
            ['</\' tag '>'], ''), confidenceScore, 'UniformOutput', 0); 
        confidenceScore = [confidenceScore{:}]'; % unnest cell
        
        formula = regexp(notesField, ...
            ['<' tag '>' NotesKeys{7} ':.*?</' tag '>'] , 'match');
        
        % strip HTML open tag and key text
        formula = cellfun(@(x) regexprep(x, ...
            ['<' tag '>' NotesKeys{7} ': '], ''), formula, ...
            'UniformOutput', 0);
        
        % strip tag close tags
        formula = cellfun(@(x) regexprep(x, ['</\' tag '>'], ''), ...
            formula, 'UniformOutput', 0); 
        formula = [formula{:}]'; % unnest cell
        
        charge = regexp(notesField, ...
            ['<' tag '>' NotesKeys{8} ':.*?</' tag '>'] , 'match');
        
        % strip HTML open tag and key text
        charge = cellfun(@(x) regexprep(x, ...
            ['<' tag '>' NotesKeys{8} ': '], ''), charge, ...
            'UniformOutput', 0);
        
        % strip tag close tags
        charge = cellfun(@(x) regexprep(x, ['</\' tag '>'], ''), ...
            charge, 'UniformOutput', 0);
        charge = [charge{:}]'; % unnest cell
    else
        errorstr = [...
            'The str variable passed to parseBoolean must be a string or ' ...
            'cell array.'];
        error(errorstr)
    end

end