%playsong({'E' 'E' 'E' 'E' 'E' 'E' 'E' 'G' 'C' 'D' 'E'},[1 1 2 1 1 2 1 1 1 1 3]);
music_sheet= im2double(rgb2gray(imread('1.bmp')));
%figure,imshow(Black_White)



Threshold = graythresh(music_sheet);
Black_White = imbinarize(music_sheet,Threshold);



invert_music_sheet = ones(size(music_sheet)) - Black_White;
%figure,imshow(invert_music_sheet)

%figure,plot(sum(invert_music_sheet,2))%horizontal projection
%[pks, locs] = findpeaks(sum(invert_music_sheet,2));
%tresh = pks > max(pks)/5;
%locs = locs .* tresh;
%pks = pks .* tresh;

music_sheet = invert_music_sheet;
music_sheet = bwmorph(music_sheet,'skel');

%figure,imshow(music_sheet),title('test')

%erode with mask #########...65
staves_only = imerode(music_sheet, ones(1,20));  
%figure,imshow(staves_only),title('test')

dilated_image = imdilate(staves_only, ones(1,50));
%figure,imshow(dilated_image)


staff = sum(music_sheet,2)/size(music_sheet,2);



lines = imbinarize(staff,0.5); % contains y coords of each staff line
lines_indexes = find(lines == 1);
lines_distance = diff(lines_indexes);

lines_indexes(lines_distance==1 | lines_distance > 75) = [];
lines_distance(lines_distance==1 | lines_distance > 75) = [];
groups = zeros(length(lines_indexes),1) - ones(length(lines_indexes),1);
for i= 1:5:length(lines_indexes)-1
   groups(i:i+4)=fix(i/5)+1; 
end



vertical_lines = imdilate(imerode(invert_music_sheet,ones(35,1)),ones(35,1));
%figure,imshow(vertical_lines)

%notes_only = imerode(music_sheet-dilated_image, ones(2,1));
notes_only = music_sheet- dilated_image - vertical_lines;

notes_only = imbinarize(notes_only,0.9);
%figure,imshow(notes_only);

notes_only = imclose(notes_only,[1; 1; 1;]);
%notes_only = imclose(notes_only,[1 0; 0 1;]);
%notes_only = imclose(notes_only,[0 1; 1 0;]);

notes_only = bwmorph(notes_only,'bridge');
figure,imshow(notes_only);





CC = bwconncomp(notes_only);

info = regionprops(CC,'Boundingbox','Area');
on_line_notes = ['F','D','B','G','E'];
above_line = ['N','E','C','A','F'];

Notations_IDs = [];
Notations_Chars = {};
Notations_Length = [];

figure,imshow(notes_only)
hold on
for k = 1 : length(info)
     BB = info(k);
     if BB.Area > 90 || BB.BoundingBox(3) >20 || BB.BoundingBox(3) < 6 ||...
             BB.BoundingBox(2)+ BB.BoundingBox(4) < lines_indexes(1)
         continue;
     end
    % if BB.BoundingBox(1) < 90
     %   continue;
    %  end
     BoxDistance = (BB.BoundingBox(2)+ BB.BoundingBox(4))-lines_indexes;
     min2indices = find(abs(BoxDistance) < 13);

     if isempty(min2indices)
         continue;
     end
     min2values = BoxDistance(min2indices);
     [min2values,sortIdx] = sort(min2values);
     min2indices = min2indices(sortIdx);
      if min(min2values) > 6 && min(min2values) < 9 %below
              [~,I] = min(min2values);
              line_index = min2indices(I);
              NoteChar = 'D';
              text(BB.BoundingBox(1),BB.BoundingBox(2)-20,'D','Color','r','FontSize',14);
      elseif min(min2values) > 9 %below awy
              [~,I] = min(min2values);
              line_index = min2indices(I);
              NoteChar = 'C';
              text(BB.BoundingBox(1),BB.BoundingBox(2)-20,'C','Color','r','FontSize',14);
      elseif ~isempty(min2values(min2values>=2.5 & min2values <= 4.5)) %on line
          line_index = min2indices(min2values>=2.5 & min2values <= 4.5);
          line_num = mod(line_index,5);
          if line_num == 0
              line_num = 5;
          end
          NoteChar = on_line_notes(line_num);
          text(BB.BoundingBox(1),BB.BoundingBox(2)-20,on_line_notes(line_num),'Color','r','FontSize',14);
         
      else%above
          [~,I] = min((abs(min2values)));
          line_index = min2indices(I);
           line_num = mod(line_index,5);
          if line_num == 0
              line_num = 5;
          end
          NoteChar = above_line(line_num);
          text(BB.BoundingBox(1),BB.BoundingBox(2)-20,above_line(line_num),'Color','r','FontSize',14);
         
      end


          x_test = round(BB.BoundingBox(1)):BB.BoundingBox(1)+BB.BoundingBox(3);
          y_test = round(BB.BoundingBox(2)):BB.BoundingBox(2)+BB.BoundingBox(4);
          group_num = groups(line_index);
          img_only = notes_only(y_test,x_test);
          note_length = DetectNote(img_only);
          if note_length == -1
              continue;
          end
          Notations_IDs = [Notations_IDs round(BB.BoundingBox(1))+group_num*10000];
          Notations_Chars = [Notations_Chars NoteChar];
          Notations_Length = [Notations_Length note_length];
          %DetectNote(img_only);
   
     text(BB.BoundingBox(1),BB.BoundingBox(2)-30,num2str(DetectNote(img_only)),'Color','g');
     rectangle('Position', [BB.BoundingBox(1),BB.BoundingBox(2),BB.BoundingBox(3),BB.BoundingBox(4)],'EdgeColor','r','LineWidth',1);
end
    [Notations_IDs,sortIdx] = sort(Notations_IDs);
     Notations_Chars = Notations_Chars(sortIdx);
     Notations_Length = Notations_Length(sortIdx);
    % arr2=char(arr2);
     playsong(Notations_Chars,Notations_Length)
