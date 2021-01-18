clear all
clc
%% Paramters:
a = 0.046; %object principle length
b = 0.012; %object minor length
N = 0.02; %object weight
mu_s = 0.2; %friction coefficient between the object and the supporting surface
mu_c = 0.8; %friction coefficient between the object and the finger
psi = 120*pi/180; %orientation of the line of pushing
d = 0.006; %initial contact position
%% Object
Ra = a/2;
Rb = b/2;%
fc_angle = atan(mu_c);
f_p = mu_s * N;
%%%%%%%%%%%% mmax for different elliptical object %%%%%%%%%%%%%%%%%%%%
m_max = mu_s*4*(N/(pi*Ra*Rb))*1.13986e-6; % Ra=0.046/2 Rb=0.012/2
% m_max = mu_s*4*(N/(pi*Ra*Rb))*7.14869e-7; % Ra=0.04/2 Rb=0.01/2
% m_max = mu_s*4*(N/(pi*Ra*Rb))*1.09427e-6; % Ra=0.05/2 Rb=0.01/2
% m_max = mu_s*4*(N/(pi*Ra*Rb))*1.8909e-6; % Ra=0.06/2 Rb=0.012/2
% m_max = mu_s*4*(N/(pi*Ra*Rb))*1.40958e-6; % Ra=0.045/2 Rb=0.015/2
% m_max = mu_s*4*(N/(pi*Ra*Rb))*2.41268e-6; % Ra=0.06/2 Rb=0.015/2
% m_max = mu_s*4*(N/(pi*Ra*Rb))*1.42482e-7; % Ra=0.023/2 Rb=0.006/2 GO STONE
% m_max = mu_s*4*(N/(pi*Ra*Rb))*1.561e-7; % Ra=0.022/2 Rb=0.007/2 CAPSURE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
c = m_max/f_p;
%% Construct limit surface

A = [1/(mu_s*N)^2 0    0;
     0     1/(mu_s*N)^2 0;
     0     0      1/(m_max)^2];

%% Gripper parameters
ap = 4*Rb; %aperture
push_dist = 0.069;
dl = 0.020;
l_lf = 0.07;
l_rf = l_lf - dl;

ep_lf = [-0.01 -0.01; %two end points of the left finger
          l_lf   0;
          1      1];
ep_rf = [ep_lf(1,1)+ap  ep_lf(1,2)+ap;
         l_rf                     0;
         1                        1];

 
%% Generate capture region
count_capture_region = 1;
dt = 0.001;
sim = 1;
obj_num = 1;
count_envelope_remain = 1;
envelope_end_set = zeros(3,1);
ap_dl_finder = zeros(3,1);

% [d_psi] = check_feasible_d_psi(Ra, Rb, l_lf, push_dist, v_p, mu_s, mu_c, N);

% for ot = (-30:5:30) * pi / 180
% for ot = 20 * pi / 180
for psi = psi%(70:10:110) * pi / 180
    ot = psi - pi/2;
    psi_visual = 90 * pi / 180;
    v_p = [-cos(psi_visual) sin(psi_visual)]' * 0.1;
    for d = d%Ra/2%0.02%Ra/3%possible_d
%     for ox=ep_lf(1,1)+Rb*sin(-ot)+0.02
%         for oy=l_lf+Rb*cos(-ot)+0.008
            d_temp = d;
            is_overpush = 0;
            is_rf_short_set = 0;
            eef_ep_lf = [             -d                              -d+l_lf*sin(-ot);
                          -sqrt(Rb^2-(-d)^2*(Rb^2/Ra^2))  -sqrt(Rb^2-(-d)^2*(Rb^2/Ra^2))-l_lf*cos(-ot);
                                       1                                    1];
            R_origin2obj = [cos(ot) -sin(ot) 0;
                            sin(ot)  cos(ot) 0;
                                0         0       1];
            eef_ep_lf_ = R_origin2obj * eef_ep_lf;
            original_obj_center = R_origin2obj*[0;0;1]+[-0.01-eef_ep_lf_(1,1);l_lf-eef_ep_lf_(2,1);0];
            ox = original_obj_center(1,1);
            oy = original_obj_center(2,1);

%             if eef_ep_lf(1,1)^2/Ra^2+eef_ep_lf(2,1)^2/Rb^2 >= 1-0.000001
            x_d = -d;
            y_d = -sqrt(Rb^2-x_d^2*(Rb^2/Ra^2));
            contact_pt = [x_d; y_d];
            eef_ep_lf(1:2,1);
            push_to_obj = norm(contact_pt-eef_ep_lf(1:2,1));
            push_to_obj_ = push_to_obj;

            [obj_pts] = createEllipticalObject(0, 0, Ra, Rb);
            obj{1} = [obj_pts;ones(1,size(obj_pts,2))];
            o_c(:,1) = [ox;oy];
            o_r(1) = ot;%0;

            R = [cos(o_r(1)) -sin(o_r(1)) o_c(1,1);
                 sin(o_r(1)) cos(o_r(1))  o_c(2,1);
                        0                0                  1          ];
            obj_origin = R * obj{1};

            contact_pt(:,1) = contact_pt;
            contact_pt_visual_temp = R * [contact_pt(:,1);1];
            contact_pt_visual(:,1) = contact_pt_visual_temp(1:2,1);

%                 envelope(:,1) = R * [Ra;0;1];
            [obj_far_point, ofp_index] = max(obj_origin(1,:));
            envelope(:,1) = obj_origin(:,ofp_index) - [contact_pt_visual(1:2,1);0] + [contact_pt_visual(1:2,1);0] - [0;push_to_obj_;0];
            if sim == 1
                vd_file = sprintf('./d=%0.4f_psi=%0.2f.avi',d,psi*180/pi);%'./poke_video/d=' + d + 'test_psi=' + (psi_visual+ox)*pi/180 + '.avi';
                movieObj = VideoWriter(vd_file);
                movieObj.FrameRate = 10;
                open(movieObj);
                h = figure;
                axis equal;
                grid on;
                hold on;
                plot(obj_origin(1,:), obj_origin(2,:), 'LineWidth', 2, 'Color', [.45 .45 .45]);
                hold on
%                     plot(envelope(1,1), envelope(2,1), 'mo');
%                     hold on;
                p1 = line([ep_lf(1,1), ep_lf(1,2)], [ep_lf(2,1), ep_lf(2,2)], ...
                  'LineWidth', 4, 'Color', [1,0,0]);
                p1.Color(4) = 0;
                p2 = line([ep_rf(1,1), ep_rf(1,2)], [ep_rf(2,1), ep_rf(2,2)], ...
                  'LineWidth', 4, 'Color', [1,0,0]);
                p2.Color(4) = 0;
                plot(envelope(1,:), envelope(2,:), 'm.', 'LineWidth', 2);
            end
            v_p_visual(:,1) = contact_pt_visual(:,1) - v_p;

            ts = 1;

            while abs(d) < Ra-0.0002 %for ts = 1:20
                if contact_pt_visual(2,ts) >= l_lf+push_dist
                    is_overpush = 1;
                    break
                end
                if push_to_obj > 0
                ep_lf = ep_lf + [0 0;norm(v_p)*dt norm(v_p)*dt;0 0];
                ep_rf = ep_rf + [0 0;norm(v_p)*dt norm(v_p)*dt;0 0];
                push_to_obj = push_to_obj - norm(v_p)*dt;
                    if sim == 1
                        lf_tip = createCircleObject(ep_lf(1,1),ep_lf(2,1),0.0005);
                        rf_tip = createCircleObject(ep_rf(1,2),ep_rf(2,1),0.0005);
% %                         plot(lf_tip(1,:), lf_tip(2,:), 'g');
                        hold on;
% %                         plot(rf_tip(1,:), rf_tip(2,:), 'g');
                        hold on;
                    end

                else
                [F_l, F_r, contact_pt_, normalized_n] = findFrictionCone('ellipse', Ra, Rb, fc_angle, f_p, d);
                [v_l, v_r, V_l, V_r] = findMotionCone(F_l, F_r, A, contact_pt(:,ts));


                % Update vp_origin in object original frame. Use vp_origion to calculate
                % object twist.
                R_n = [cos(o_r(ts)) -sin(o_r(ts));
                       sin(o_r(ts)) cos(o_r(ts))];
                n_update = R_n * normalized_n;
                if d >= 0
                    if n_update(2) >= 0
                        n_x_angle = acos(dot(n_update, [1;0]));
                    else
                    %     n_x_angle = acos(dot(n_update, [1;0]));
                        n_x_angle = -acos(dot(n_update, [1;0]));
                    end
                    n_vp_angle = pi - (n_x_angle + psi_visual);
                    n_normalize_x_angle = acos(dot(normalized_n, [1;0]));
                    vp_origin_x_angle = n_normalize_x_angle + n_vp_angle;
                    vp_origin = [cos(vp_origin_x_angle); sin(vp_origin_x_angle)];
                else
                    if n_update(2) >= 0
                        n_x_angle = acos(dot(n_update, [-1;0]));
                    else
                    %     n_x_angle = acos(dot(n_update, [1;0]));
                        n_x_angle = -acos(dot(n_update, [-1;0]));
                    end
                    n_vp_angle = psi_visual - n_x_angle;
                    n_normalize_x_angle = acos(dot(normalized_n, [-1;0]));
                    vp_origin_x_angle = n_normalize_x_angle + n_vp_angle;
                    vp_origin = [cos(pi-vp_origin_x_angle); sin(pi-vp_origin_x_angle)];
                end
                % line([contact_pt(1,ts), contact_pt(1,ts)-vp_origin(1)/100], [contact_pt(2,ts),contact_pt(2,ts)+vp_origin(2)/100], 'LineWidth', 2, 'Color', [0,1,0])

                % Determine contact mode
                vlvr = acos(dot(v_l, v_r)/(norm(v_l)*norm(v_r))); %angle between v_l and v_r
                flfr = acos(dot(F_l, F_r)/(norm(F_l)*norm(F_r)));
                if d >= 0
                    vr_vpOrigin = acos(dot(v_r, vp_origin)/(norm(v_r)*norm(vp_origin))); %angle between v_r and vp_origin
                    if vr_vpOrigin < vlvr
                        mode = 'stick';
                    else
                        mode = 'slip';
                    end
                else
                    vl_vpOrigin = acos(dot(v_l, vp_origin)/(norm(v_l)*norm(vp_origin))); %angle between v_l and vp_origin
                    if vl_vpOrigin < vlvr
                        mode = 'stick';
                    else
                        mode = 'slip';
                    end
                end

                % Compute object twist
                if strcmp(mode, 'slip')
                    if d >= 0
                        k(ts) = dot(vp_origin, normalized_n) / dot(v_l, normalized_n);
                        v_c = k(ts) * v_l;
                        v_slip = vp_origin - v_c;
                        V_o = k(ts) * V_l;
                    else
                        k(ts) = dot(vp_origin, normalized_n) / dot(v_r, normalized_n);
                        v_c = k(ts) * v_r;
                        v_slip = vp_origin - v_c;
                        V_o = k(ts) * V_r;
                    end
                elseif strcmp(mode,'stick')
                    xc = contact_pt(1,ts);
                    yc = contact_pt(2,ts);
                    vpx = vp_origin(1);
                    vpy = vp_origin(2);
                    V_o = [((c^2+xc^2)*vpx+xc*yc*vpy)/(c^2+xc^2+yc^2);
                           (xc*yc*vpx+(c^2+yc^2)*vpy)/(c^2+xc^2+yc^2);
                           (xc*vpy-yc*vpx)/(c^2+xc^2+yc^2)];
                    v_slip = 0;
                end

                R_current = [cos(o_r(ts)) -sin(o_r(ts));
                             sin(o_r(ts)) cos(o_r(ts))];
                v_o_current = R_current * V_o(1:2,:);
                trans_o = v_o_current(1:2,:) * dt;
                rot_o = V_o(3) * dt;
                if rot_o > 0
                    break;
                end
                if rot_o < 0.008 && is_rf_short_set == 1
                    rf_short_idx = ts;
                    is_rf_short_set = 1;
                end

                v_slip_current = v_slip;
                motion_f = v_slip_current * dt;

                % Update object pose
                o_c(:,ts+1) = o_c(:,ts) + trans_o;
                o_r(ts+1) = o_r(ts) + rot_o;
                R = [cos(o_r(ts+1)) -sin(o_r(ts+1)) o_c(1,ts+1);
                     sin(o_r(ts+1)) cos(o_r(ts+1))  o_c(2,ts+1);
                            0                0                  1          ];
                obj{ts+1} = R * obj{1};

                % Update finger pose
                contact_pt(:,ts+1) = contact_pt(:,ts) + motion_f;
                % plot(contact_pt(1,ts+1), contact_pt(2,ts+1), 'm*', 'LineWidth', 5);
                %hold on;
                contact_pt_visual_temp = R * [contact_pt(:,ts+1);1];
                contact_pt_visual(:,ts+1) = contact_pt_visual_temp(1:2,:);


                obj_temp = obj{ts+1};
                [obj_far_point, ofp_index] = max(obj_temp(1,:));
                envelope(:,ts+1) = obj_temp(:,ofp_index) - [contact_pt_visual(1:2,ts);0] + [contact_pt_visual(1:2,1);0] - [0;push_to_obj_;0];
                obj_in_finger = obj{ts+1} - repmat([contact_pt_visual(1:2,ts);0],1,length(obj{ts+1})) ...
                    + repmat([contact_pt_visual(1:2,1);0],1,length(obj{ts+1})) - repmat([0;push_to_obj_;0],1,length(obj{ts+1}));
                if sim == 1
                    plot(envelope(1,ts), envelope(2,ts), 'm.', 'LineWidth', 2);
                    hold on;
                    plot(obj_in_finger(1,:), obj_in_finger(2,:), 'LineWidth', 2, 'Color', [.45 .45 .45]);
                    %fill(obj_in_finger(1,:), obj_in_finger(2,:),[.85 .85 .85]);
                    %alpha(0.25)
                    hold on;
                end                   

                % Update position of right finger
                push_forward = contact_pt_visual(2,ts+1)-contact_pt_visual(2,ts);
                ep_rf = ep_rf + [0 0;push_forward push_forward;0 0];
                if sim == 1
                    rf_tip = createCircleObject(ep_rf(1,2),ep_rf(2,1),0.0005);
% %                     plot(rf_tip(1,:), rf_tip(2,:),'g');
                end
                R_obj2origin = [cos(o_r(ts+1)) -sin(o_r(ts+1)) o_c(1,ts+1);
                                sin(o_r(ts+1))  cos(o_r(ts+1)) o_c(2,ts+1);
                                0               0               1];

                % Update v_p
                v_p_visual(:,ts+1) = contact_pt_visual(:,ts+1) - v_p;
%                     line([contact_pt_visual(1,ts+1), v_p_visual(1,ts+1)], [contact_pt_visual(2,ts+1), v_p_visual(2,ts+1)], 'LineWidth', 2, 'Color', [1,0,0])
                R_vp = [cos(o_r(ts+1)) -sin(o_r(ts+1));
                        sin(o_r(ts+1)) cos(o_r(ts+1))];



                d = -contact_pt(1,ts+1);
                ts = ts +1;

                if sim == 1
                    frame = getframe(gcf);
                    writeVideo(movieObj, frame);
                end

                end
            end
%                 close(movieObj);
            if sim == 1
                obj_in_finger = obj{ts} - repmat([contact_pt_visual(1:2,ts);0],1,length(obj{ts})) ...
                    + repmat([contact_pt_visual(1:2,1);0],1,length(obj{ts})) - repmat([0;push_to_obj_;0],1,length(obj{ts}));
                plot(envelope(1,:), envelope(2,:), 'r', 'LineWidth', 4);
                hold on;
                plot(obj_in_finger(1,:), obj_in_finger(2,:), 'LineWidth', 3, 'Color', [0.1 0.1 0.1]);
                hold on;
                fill(obj_in_finger(1,:), obj_in_finger(2,:),[.55 .55 .55]);
                alpha(0.75)
                
                p1 = line([ep_lf(1,1), ep_lf(1,2)], [ep_lf(2,1), ep_lf(2,2)], ...
                  'LineWidth', 7, 'Color', [0.7,0.7,0.7]);
                p1.Color(4) = 1;
                ep_rf = [ep_lf(1,1)+ap  ep_lf(1,2)+ap;
                         l_lf                     0-0.02;
                         1                        1];
%                 p2 = line([ep_rf(1,1), ep_rf(1,2)], [ep_rf(2,1), ep_rf(2,2)], ...
%                   'LineWidth', 4, 'Color', [1,0,0],'LineStyle','--');
%                 p2.Color(4) = 0.5;
                close(movieObj);
            end

            
            if is_overpush ~= 1
                
                d_collect(:,obj_num) = [obj_num; d_temp];
                envelope_set{obj_num} = envelope;
                [~,ap_dl_finder(3,1)] = max(envelope(1,:));
                ap_dl_finder(1:2,1) = [envelope(1,ap_dl_finder(3,1));l_lf];
                ap_dl(:,2*obj_num-1) = ap_dl_finder(:,1).*[1;-1;1]+[-ep_lf(1,1);ep_lf(2,1);0];
                [~, ap_dl_finder(3,2)] = min(envelope(2,1:length(envelope)-2));
                ap_dl_finder(1:2,2) = envelope(1:2,ap_dl_finder(3,2));
                ap_dl(:,2*obj_num) = ap_dl_finder(:,2).*[1;-1;1]+[-ep_lf(1,1);ep_lf(2,1);0];

    %             end

                R = [cos(o_r(ts)) -sin(o_r(ts)) o_c(1,ts);
                     sin(o_r(ts)) cos(o_r(ts))  o_c(2,ts);
                            0                0                  1          ];
                ellipse_ep = R * [-Ra Ra;
                                    0  0;
                                    1  1];
    %             plot([ellipse_ep(1,1) ellipse_ep(1,2)], [ellipse_ep(2,1) ellipse_ep(2,2)], 'LineWidth', 2, 'Color', [1,1,0])

                capture_region(:,count_capture_region) = [ox;oy;(psi_visual+ot)*180/pi];
                act_push_dist(obj_num) = contact_pt_visual(2,ts) - l_lf;
%                 d_collect(:,obj_num) = [obj_num; d_temp];
%                 envelope_set{obj_num} = envelope;
% %                 envelope_end_set(:,obj_num) = envelope(:,ts);
%                 aperture_cand(obj_num) = max(envelope(1,:));
%                 [~, ap_dl_finder(3,obj_num)] = min(envelope(2,:));
%                 ap_dl_finder(1:2,obj_num) = envelope(1:2,ap_dl_finder(3,obj_num));
                count_capture_region = count_capture_region + 1;
                obj_num = obj_num + 1;
            end
            
%         end
    end
end
