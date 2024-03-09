import cv2
import numpy as np
import matplotlib
import math
from matplotlib.pyplot import imshow
from matplotlib import pyplot as plt
import random

def dist(p1, p2):
    return math.sqrt((p1[0]-p2[0])**2 + (p1[1]-p2[1])**2)

def distpointline(p1, p2, p3):
    a1 = np.array(p1)
    a2 = np.array(p2)
    a3 = np.array(p3)
    return np.linalg.norm(np.cross(a2-a1, a1-a3)) / np.linalg.norm(a2-a1)

img = cv2.imread('lines2.png')
gray = cv2.cvtColor(img,cv2.COLOR_BGR2GRAY)

kernel_size = 5
blur_gray = cv2.GaussianBlur(gray,(kernel_size, kernel_size),0)

low_threshold = 50
high_threshold = 150
edges = cv2.Canny(blur_gray, low_threshold, high_threshold)

rho = 1  # distance resolution in pixels of the Hough grid
theta = np.pi / 180  # angular resolution in radians of the Hough grid
threshold = 60  # minimum number of votes (intersections in Hough grid cell)
min_line_length = 50  # minimum number of pixels making up a line
max_line_gap = 20  # maximum gap in pixels between connectable line segments
line_image = np.copy(img) * 0  # creating a blank to draw lines on
prefilter = np.copy(img) * 0

# Run Hough on edge detected image
# Output "lines" is an array containing endpoints of detected line segments
lines = cv2.HoughLinesP(edges, rho, theta, threshold, np.array([]),
                    min_line_length, max_line_gap)

width = img.shape[1]
height = img.shape[0]

points = []
edges = []

for line in lines:
    for x1,y1,x2,y2 in line:
        x1rat = float(x1) / width
        x2rat = float(x2) / width
        y1rat = float(y1) / height
        y2rat = float(y2) / height

        p1 = (x1rat, y1rat)
        p2 = (x2rat, y2rat)

        idx1 = -1
        idx2 = -1
        for i in range(len(points)):
            p = points[i]
            if dist(p, p1) < 0.1:
                idx1 = i
            if dist(p, p2) < 0.1:
                idx2 = i
        
        if idx1 == -1:
            idx1 = len(points)
            points.append(p1)
        if idx2 == -1:
            idx2 = len(points)
            points.append(p2)
        
        if idx1 == idx2:
            continue
        
        valid = True
        for e in edges:
            if e[0] == idx1 and e[1] == idx2:
                valid = False
                break
            if e[0] == idx2 and e[1] == idx1:
                valid = False
                break
        
        if valid:
            edges.append((idx1, idx2))
            cv2.line(prefilter,(int(points[idx1][0]*width),int(points[idx1][1]*height)),(int(points[idx2][0]*width),int(points[idx2][1]*height)),(random.randint(0, 255),random.randint(0, 255),random.randint(0, 255)),1)

# Draw the lines on the  image
lines_edges = cv2.addWeighted(img, 0.8, prefilter, 1, 0)

cv2.imshow("res", prefilter)
cv2.waitKey(0)

"""
IMPROVEMENTS
- figure out best thresholds
- if line A passes through line B, split line B into two lines at that point
"""

# merge lines if slopes are similar and lines are close
toremove = []
for i in range(len(edges)):
    edge1 = edges[i]
    if edge1 not in toremove:
        for edge2 in edges:
            # changed = False
            if edge1 != edge2 and edge2 not in toremove:
                # shouldignore = False
                # if edge1[0] == edge2[0] or edge1[0] == edge2[1]:
                #     for e in edges:
                #         if e != edge1 and e != edge2 and (e[0] == edge1[0] or e[1] == edge1[0]):
                #             shouldignore = True
                #             break
                # elif edge1[1] == edge2[0] or edge1[1] == edge2[1]:
                #     for e in edges:
                #         if e != edge1 and e != edge2 and (e[0] == edge1[0] or e[1] == edge1[0]):
                #             shouldignore = True
                #             break
                # if shouldignore:
                #     continue

                # r1 = distpointline(points[edge1[0]], points[edge1[1]], (0,0))
                # r2 = distpointline(points[edge2[0]], points[edge2[1]], (0,0))
                theta1 = math.atan2(points[edge1[0]][1] - points[edge1[1]][1], points[edge1[0]][0] - points[edge1[1]][0])
                theta2 = math.atan2(points[edge2[0]][1] - points[edge2[1]][1], points[edge2[0]][0] - points[edge2[1]][0])

                close = (distpointline(points[edge1[0]], points[edge1[1]], points[edge2[0]]) < 0.05) or (distpointline(points[edge1[0]], points[edge1[1]], points[edge2[1]]) < 0.05)
                
                if close and abs(theta1 - theta2) < 0.2 or abs(theta1 - theta2) > 6.08 or (abs(theta1 - theta2) > 3.04 and abs(theta1 - theta2) < 3.24):
                    # print((abs(theta1 - theta2), close))
                    len1 = dist(points[edge1[0]], points[edge1[1]])
                    len12 = (len1 / 2) + 0.005
                    mid1 = ((points[edge1[0]][0] + points[edge1[1]][0])/2, (points[edge1[0]][1] + points[edge1[1]][1])/2)

                    #print((points[edge1[0]], points[edge1[1]], mid1, len1))

                    dist21 = dist(points[edge2[0]], mid1)
                    dist22 = dist(points[edge2[1]], mid1)
                    #print((dist21, dist22, len12))
                    #print((points[edge2[0]], mid1, dist21))

                    if dist21 < len12 and dist22 < len12:
                        # print("0")
                        # changed = True
                        toremove.append(edge2)
                    elif dist21 < len12:
                        # print("1")
                        # changed = True
                        if dist(points[edge2[1]], points[edge1[0]]) > dist(points[edge2[1]], points[edge1[1]]):
                            edges[i] = (edge1[0], edge2[1])
                        else:
                            edges[i] = (edge1[1], edge2[1])
                        toremove.append(edge2)
                        i -= 1
                        break
                    elif dist22 < len12:
                        # print("2")
                        # changed = True
                        if dist(points[edge2[0]], points[edge1[0]]) > dist(points[edge2[0]], points[edge1[1]]):
                            edges[i] = (edge1[0], edge2[0])
                        else:
                            edges[i] = (edge1[1], edge2[0])
                        toremove.append(edge2)
                        i -= 1
                        break
            
            # if changed:
            #     for edge in edges:
            #         cv2.line(line_image,(int(points[edge[0]][0]*width),int(points[edge[0]][1]*height)),(int(points[edge[1]][0]*width),int(points[edge[1]][1]*height)),(random.randint(0, 255),random.randint(0, 255),random.randint(0, 255)),1)

            #     # Draw the lines on the  image
            #     lines_edges = cv2.addWeighted(img, 0.8, line_image, 1, 0)
                
            #     cv2.imshow("res", line_image)
            #     cv2.waitKey(0)
            #     line_image *= 0
            
# remove vertices that are only used once
changed = True
while changed:
    changed = False

    point_uses = []
    for i in range(len(points)):
        point_uses.append(0)
    
    for edge in edges:
        if edge not in toremove:
            point_uses[edge[0]] += 1
            point_uses[edge[1]] += 1
    
    for i in range(len(point_uses)):
        if point_uses[i] < 2:
            for edge in edges:
                if edge not in toremove:
                    if edge[0] == i or edge[1] == i:
                        toremove.append(edge)
                        changed = True

for edge in toremove:
    if edge in edges:
        edges.remove(edge)

cleaned_points = []
cleaned_edges = []
for edge in edges:
    p1 = points[edge[0]]
    p2 = points[edge[1]]

    idx1 = -1
    idx2 = -1

    if p1 in cleaned_points:
        idx1 = cleaned_points.index(p1)
    else:
        idx1 = len(cleaned_points)
        cleaned_points.append(p1)
    
    if p2 in cleaned_points:
        idx2 = cleaned_points.index(p2)
    else:
        idx2 = len(cleaned_points)
        cleaned_points.append(p2)
    
    cleaned_edges.append((idx1, idx2))

for edge in cleaned_edges:
    cv2.line(line_image,(int(cleaned_points[edge[0]][0]*width),int(cleaned_points[edge[0]][1]*height)),(int(cleaned_points[edge[1]][0]*width),int(cleaned_points[edge[1]][1]*height)),(random.randint(0, 255),random.randint(0, 255),random.randint(0, 255)),1)

# Draw the lines on the  image
lines_edges = cv2.addWeighted(img, 0.8, line_image, 1, 0)

cv2.imshow("res", line_image)
cv2.waitKey(0)

f = open("data.drpd", "w")

f.write(str(len(cleaned_points)) + "\n")
for point in cleaned_points:
    f.write(str(point) + "\n")

f.write(str(len(cleaned_edges)) + "\n")
for edge in cleaned_edges:
    f.write(str(edge) + "\n")

f.close()