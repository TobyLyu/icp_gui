# main.py
import sys
from PySide6.QtCore import QObject, Slot, Signal
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtGui import QImage
from PySide6.QtQuick import QQuickImageProvider
import open3d as o3d
import numpy as np
import copy
from scipy.spatial.transform import Rotation as R
import threading
import warnings

class Open3DImageProvider(QQuickImageProvider):
    def __init__(self):
        super().__init__(QQuickImageProvider.Image)
        # Initialize Open3D renderer and scene here
        self.vis = o3d.visualization.Visualizer()
        self.vis.create_window(window_name='o3d_headless', width=1520, height=1080, visible=False)
        
        render_opt = self.vis.get_render_option()
        render_opt.light_on = False
        render_opt.point_size = 1
        render_opt.point_color_option = o3d.visualization.PointColorOption.Color
        # render_opt.point_show_normal = False

    def requestImage(self, id, size, requestedSize):
        # Render the scene to an image
        try:
            img = self.vis.capture_screen_float_buffer(do_render=True)
        except:
            img = np.zeros([1520, 1080])

        # Convert Open3D image to QImage
        img_data = np.asarray(img) * 255
        h, w, c = img_data.shape

        # Ensure the image is in the correct format
        img_data = img_data.astype(np.uint8)

        # Create a QImage from the numpy array
        qimg = QImage(img_data.data, w, h, QImage.Format_RGB888).copy()
        return qimg

class Backend(QObject):
    # imageChanged = Signal()
    _valueChanged = Signal()
    def __init__(self, root_object, image_P):
        super().__init__()
        o3d.utility.set_verbosity_level(o3d.utility.VerbosityLevel.Debug)
        self.root_object = root_object
        self.image_P = image_P

        
        self.wait = False
        self.target_path = ""
        self.source_path = ""
        self.save_trans_path = ""
        self.save_pcd_path = ""
        self.transformation = np.eye(4)
        self.old_transformation = np.eye(4)
        self.source_pcd = None
        self.source_pcd_t = None
        self._source_loaded = False
        self.target_pcd = None
        self.target_pcd_t = None
        self._target_loaded = False

        self.view = None

        self.threshold = 10
        self.max_iteration = 100
        self.stop_rmse = 0.0001
        self.target_voxel_size = 0.05
        self.source_voxel_size = 0.05
        self.roll = 0.0
        self.pitch = 0.0
        self.yaw = 0.0
        self.x = 0.0
        self.y = 0.0
        self.z = 0.0
        
        self.to_stop = False
         
    @Slot(result=str)
    def change_disp_mode(self):
        render_opt_old = self.image_P.vis.get_render_option()
        self.image_P.vis.destroy_window()
        self.image_P.vis.create_window(window_name='o3d_view', width=1520, height=1080, visible=True)
        render_opt = self.image_P.vis.get_render_option()
        render_opt.light_on = render_opt_old.light_on
        render_opt.point_size = render_opt_old.point_size
        render_opt.point_color_option = render_opt_old.point_color_option
        if self.view: self.image_P.vis.set_view_status(self.view)
        self.image_P.vis.clear_geometries()
        if self.source_pcd:
            if not self.view: self.image_P.vis.add_geometry(self.source_pcd, reset_bounding_box=True)
            else: self.image_P.vis.add_geometry(self.source_pcd, reset_bounding_box=False)
        if self.target_pcd:
            if not self.view: self.image_P.vis.add_geometry(self.target_pcd, reset_bounding_box=True)
            else: self.image_P.vis.add_geometry(self.target_pcd, reset_bounding_box=False)
        self.update_render()
        self.image_P.vis.run()
        render_opt_old = self.image_P.vis.get_render_option()
        self.view = self.image_P.vis.get_view_status()
        # o3d.visualization.draw_geometries([self.source_pcd])
        self.image_P.vis.destroy_window()
        self.image_P.vis.create_window(window_name='o3d_headless', width=1520, height=1080, visible=False)
        render_opt = self.image_P.vis.get_render_option()
        render_opt.light_on = render_opt_old.light_on
        render_opt.point_size = render_opt_old.point_size
        render_opt.point_color_option = render_opt_old.point_color_option
        self.image_P.vis.set_view_status(self.view)
        self.image_P.vis.clear_geometries()
        if self.source_pcd:
            self.image_P.vis.add_geometry(self.source_pcd, reset_bounding_box=False)
        if self.target_pcd:
            self.image_P.vis.add_geometry(self.target_pcd, reset_bounding_box=False)
        # self.image_P.vis.set_view_status(self.view)
        self.update_render()
        
    @Slot(result=str)
    def reset_disp(self):
        self.image_P.vis.reset_view_point()
        self.view = self.image_P.vis.get_view_status()
         
    @Slot(str, result=float)
    def get_value(self, axis):
        if axis == "Roll":
            return self.roll
        elif axis == "Pitch":
            return self.pitch
        elif axis == "Yaw":
            return self.yaw
        elif axis == "X":
            return self.x
        elif axis == "Y":
            return self.y
        elif axis == "Z":
            return self.z
   
    @Slot(result=str)
    def get_path(self):
        self.target_path = self.root_object.property("target_full_path")
        self.source_path = self.root_object.property("source_full_path")
        if self.target_path:
            self.target_path = self.target_path[7:]
        if self.source_path:
            self.source_path = self.source_path[7:]
    
    @classmethod
    def _load_file_(cls, path, this_object, voxel_size):
        msg = ""
        filename = path.split("/")[-1]
        msg += "Loading ...\n"
        this_object.receivedInfo.emit(msg)
        print("Loading ...".format(filename))
        scans_t = o3d.t.io.read_point_cloud(path)
        msg += "Removing NaN/Inf points ...\n"
        this_object.receivedInfo.emit(msg)
        print("Removing NaN/Inf points ...")
        (scans_t, mask) = scans_t.remove_non_finite_points()
        scans = scans_t.to_legacy()
        # scans = o3d.io.read_point_cloud(path, remove_nan_points=True, remove_infinite_points=True)
        if not np.asarray(scans.points).shape[0]:
            msg += "PCD file dose not contain any points!"
            this_object.receivedInfo.emit(msg)
            return scans
        msg += "Downsampling ... Voxel size is {}\n".format(voxel_size)
        this_object.receivedInfo.emit(msg)
        print("Downsampling {} ... ".format(filename))
        scans_d = scans.voxel_down_sample(voxel_size=voxel_size)
        scans_t_d = scans_t.voxel_down_sample(voxel_size=voxel_size)
        # msg += "Re-calculate normals ...\n"
        # this_object.receivedInfo.emit(msg)
        # print("Re-calculate normals ...")
        # scans_d.estimate_normals()
        msg += "Finished.\n"
        msg += "-------------------------------------\n"
        msg += "Loaded PCD file: {}\n".format(filename)
        msg += "Full size: {} points\n".format(np.asarray(scans.points).shape[0])
        msg += "Valid size: {} points\n".format(mask.to(o3d.core.Dtype.Int32).sum().item())
        msg += "Downsampled size: {} points".format(np.asarray(scans_d.points).shape[0])
        this_object.receivedInfo.emit(msg)
        
        return scans_d, scans_t_d
    
    def load_file_thread_cb(self, item):
        this_object = self.root_object.findChild(QObject, "button_open_{}".format(item))
        if item == "target":
            self.target_pcd, self.target_pcd_t = self._load_file_(self.target_path, this_object, self.target_voxel_size)
            self.target_pcd.paint_uniform_color([0, 0.651, 0.929])
        elif item == "source":
            self.source_pcd, self.source_pcd_t = self._load_file_(self.source_path, this_object, self.source_voxel_size)
            self.source_pcd.paint_uniform_color([1, 0.706, 0])
        this_object.finished.emit(True)
    
    @Slot(str, result=bool)
    def add_item_geometry(self, item):
        if item == "target":
            if not self.view:
                self.image_P.vis.add_geometry(self.target_pcd, reset_bounding_box=True)
                self.view = self.image_P.vis.get_view_status()
                self._target_loaded = True
            else:
                self.image_P.vis.add_geometry(self.target_pcd, reset_bounding_box=False)
                self._target_loaded = True
        elif item == "source":
            if not self.view:
                self.image_P.vis.add_geometry(self.source_pcd, reset_bounding_box=True)
                self.view = self.image_P.vis.get_view_status()
                self._source_loaded = True
            else:
                self.image_P.vis.add_geometry(self.source_pcd, reset_bounding_box=False)  
                self._source_loaded = True 
        self.update_render()
            
    
    @Slot(str, result=bool)
    def load_file_qml_cb(self, item):
        if item == "target":
            if self._target_loaded: 
                self.image_P.vis.remove_geometry(self.target_pcd, reset_bounding_box=False)
            open_t = threading.Thread(name="open_".format(item), target=self.load_file_thread_cb, args=(item, ))
        elif item == "source":
            if self._source_loaded:
                self.image_P.vis.remove_geometry(self.source_pcd, reset_bounding_box=False)
                self.old_transformation = np.eye(4)
            open_t = threading.Thread(name="open_".format(item), target=self.load_file_thread_cb, args=(item, ))
        open_t.setDaemon(True)
        open_t.start()

        
    @Slot(float, str, result=str)
    def update_init(self, angle, axis):
        if axis == "Roll":
            self.roll = angle
        elif axis == "Pitch":
            self.pitch = angle
        elif axis == "Yaw":
            self.yaw = angle
        elif axis == "X":
            self.x = angle
        elif axis == "Y":
            self.y = angle
        elif axis == "Z":
            self.z = angle
        self.update_init_mtx()

    @Slot(float, str, result=str)
    def update_load_param(self, value, param):
        if param == "target":
            self.target_voxel_size = value
        elif param == "source":
            self.source_voxel_size = value

    @Slot(float, str, result=str)
    def update_icp_param(self, value, param):
        if param == "max_dist":
            self.threshold = value
        elif param == "max_iter":
            self.max_iteration = int(value)
        elif param == "stop_rmse":
            self.stop_rmse = value

    @Slot(result=bool)
    def update_render(self):
        if self.source_pcd:
            self.image_P.vis.update_geometry(self.source_pcd)
        if self.target_pcd:
            self.image_P.vis.update_geometry(self.target_pcd)
        status = self.image_P.vis.poll_events()
        self.image_P.vis.update_renderer()
        return status
        
    def update_init_result(self):
        if self.source_pcd:
            new_transform = self.transformation @ np.linalg.inv(self.old_transformation)
            self.source_pcd.transform(new_transform)
            self.old_transformation = copy.deepcopy(self.transformation)

    def update_init_mtx(self):    
        self.transformation[:3, :3] = R.from_euler('xyz', [self.roll, self.pitch, self.yaw], degrees=False).as_matrix()
        self.transformation[0, 3] = self.x
        self.transformation[1, 3] = self.y
        self.transformation[2, 3] = self.z
        if not self.wait:
            self.update_init_result()
        
    def update_gui_value(self):
        rpy = R.from_matrix(self.transformation[:3, :3]).as_euler('xyz', degrees=False)
        self.roll = rpy[0]
        self.pitch = rpy[1]
        self.yaw = rpy[2]
        self.x = self.transformation[0, 3]
        self.y = self.transformation[1, 3]
        self.z = self.transformation[2, 3]
        # ipdb.set_trace()
        # textInput_yaw = self.root_object.findChild(QObject, "textInput_yaw")
        # slider_yaw = self.root_object.findChild(QObject, "slider_yaw")
        # textInput_yaw.setProperty("text", '{:.2f}'.format(rpy[2]))
        # slider_yaw.setProperty("value", float(rpy[2]))
        # slider_yaw.update()

    @Slot(result=str)
    def stop_icp(self):
        self.to_stop = True

    def do_icp(self):
        botton_start = self.root_object.findChild(QObject, "button_start")
        msg = ""
        self.to_stop = False
        evaluation = o3d.pipelines.registration.evaluate_registration(self.source_pcd, self.target_pcd, 
                                                                      self.threshold, self.transformation)
        old_rmse = evaluation.inlier_rmse
        try:
            for i in range(self.max_iteration):
                reg_p2p = o3d.pipelines.registration.registration_icp(
                    self.source_pcd, self.target_pcd, self.threshold, np.eye(4),
                    o3d.pipelines.registration.TransformationEstimationPointToPoint(),
                    o3d.pipelines.registration.ICPConvergenceCriteria(max_iteration=1))
                self.source_pcd.transform(reg_p2p.transformation)
                self.transformation = reg_p2p.transformation @ self.transformation
                self.update_gui_value()
                step_msg = "ICP Iteration #{}, fitness: {:.4f}, RMSE: {:.4f}\n".format(i, reg_p2p.fitness, reg_p2p.inlier_rmse)
                botton_start.processing.emit(step_msg)
                if abs(reg_p2p.inlier_rmse - old_rmse) < self.stop_rmse:
                    break
                old_rmse = reg_p2p.inlier_rmse
                if self.to_stop:
                    break
            self.old_transformation = copy.deepcopy(self.transformation)
            if not self.to_stop:
                msg = "Finished!\n------------------------------\n"
            else: 
                msg = "Stopped!\n------------------------------\n"
            msg += "No. of iterations: {}\n".format(i+1)
            msg += "Final fitness: {:.4f}, RMSE: {:.4f}\n".format(reg_p2p.fitness, reg_p2p.inlier_rmse)
            msg += "------------------------------\n"
            msg += "Estimated transformation is:\n" + \
            "{:.4f},\t{:.4f},\t{:.4f},\t{:.4f}\n{:.4f},\t{:.4f},\t{:.4f},\t{:.4f}\n{:.4f},\t{:.4f},\t{:.4f},\t{:.4f}\n{:.4f},\t{:.4f},\t{:.4f},\t{:.4f}\n".format( \
                self.transformation[0, 0], self.transformation[0, 1], self.transformation[0, 2], self.transformation[0, 3], \
                self.transformation[1, 0], self.transformation[1, 1], self.transformation[1, 2], self.transformation[1, 3], \
                self.transformation[2, 0], self.transformation[2, 1], self.transformation[2, 2], self.transformation[2, 3], \
                self.transformation[3, 0], self.transformation[3, 1], self.transformation[3, 2], self.transformation[3, 3], \
                    )
            # botton_start.succeed.emit(True)
        except Exception as error:
            msg = "Start ICP Error!"
            print(error)
            # msg = "Error!"
        botton_start.finished.emit(msg)

    @Slot(result=str)
    def button_start_cb(self):
        icp_t = threading.Thread(target=self.do_icp)
        icp_t.setDaemon(True)
        icp_t.start()
        
    @Slot(result=str)
    def save_transform(self):
        self.save_trans_path = self.root_object.property("save_trans_path")
        self.save_trans_path = self.save_trans_path[7:]
        # print(self.save_path)
        # filename = os.path.join(self.save_path, "transformation.txt")
        np.savetxt(self.save_trans_path, self.transformation, delimiter=",")

    @Slot(result=str)
    def save_pcd(self):
        self.save_pcd_path = self.root_object.property("save_pcd_path")
        self.save_pcd_path = self.save_pcd_path[7:]
        # print(self.save_path)
        # filename = os.path.join(self.save_path, "transformation.txt")
        combined_pcd = copy.deepcopy(self.source_pcd_t).transform(self.transformation) + self.target_pcd_t
        # o3d.io.write_point_cloud(self.save_pcd_path, combined_pcd)
        o3d.t.io.write_point_cloud(self.save_pcd_path, combined_pcd)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    engine = QQmlApplicationEngine()

    # 加载 QML 文件
    open3d_image_provider = Open3DImageProvider()
    engine.addImageProvider("open3d", open3d_image_provider)

    engine.load("Screen01.ui.qml")

    if not engine.rootObjects():
        sys.exit(-1)

    # 创建后端对象并注册到 QML 中
    backend = Backend(engine.rootObjects()[0], open3d_image_provider)
    engine.rootContext().setContextProperty("backend", backend)

    sys.exit(app.exec())