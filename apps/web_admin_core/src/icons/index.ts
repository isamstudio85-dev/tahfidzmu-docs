import React from 'react';

const createIcon = (name: string) => ({ className, width, height, fill, stroke, strokeWidth, viewBox, xmlns, ...rest }: any) => {
  return React.createElement('span', {
    className: `material-symbols-rounded ${className || ''}`,
    style: { 
      fontSize: width || '24px', 
      width: width || '24px',
      height: height || '24px',
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      color: fill && fill !== 'none' ? fill : 'inherit' 
    },
    ...rest
  }, name);
};

export const PlusIcon = createIcon('add');
export const CloseIcon = createIcon('close');
export const BoxIcon = createIcon('inventory_2');
export const CheckCircleIcon = createIcon('check_circle');
export const AlertIcon = createIcon('warning');
export const InfoIcon = createIcon('info');
export const ErrorIcon = createIcon('error');
export const BoltIcon = createIcon('bolt');
export const ArrowUpIcon = createIcon('arrow_upward');
export const ArrowDownIcon = createIcon('arrow_downward');
export const FolderIcon = createIcon('folder');
export const VideoIcon = createIcon('videocam');
export const AudioIcon = createIcon('audiotrack');
export const GridIcon = createIcon('grid_view');
export const FileIcon = createIcon('insert_drive_file');
export const DownloadIcon = createIcon('download');
export const ArrowRightIcon = createIcon('arrow_forward');
export const GroupIcon = createIcon('group');
export const BoxIconLine = createIcon('inventory_2');
export const ShootingStarIcon = createIcon('stars');
export const DollarLineIcon = createIcon('attach_money');
export const TrashBinIcon = createIcon('delete');
export const AngleUpIcon = createIcon('keyboard_arrow_up');
export const AngleDownIcon = createIcon('keyboard_arrow_down');
export const AngleLeftIcon = createIcon('keyboard_arrow_left');
export const AngleRightIcon = createIcon('keyboard_arrow_right');
export const PencilIcon = createIcon('edit');
export const CheckLineIcon = createIcon('check');
export const CloseLineIcon = createIcon('close');
export const ChevronDownIcon = createIcon('expand_more');
export const ChevronUpIcon = createIcon('expand_less');
export const PaperPlaneIcon = createIcon('send');
export const LockIcon = createIcon('lock');
export const EnvelopeIcon = createIcon('mail');
export const UserIcon = createIcon('person');
export const CalenderIcon = createIcon('calendar_month');
export const EyeIcon = createIcon('visibility');
export const EyeCloseIcon = createIcon('visibility_off');
export const TimeIcon = createIcon('schedule');
export const CopyIcon = createIcon('content_copy');
export const ChevronLeftIcon = createIcon('chevron_left');
export const UserCircleIcon = createIcon('account_circle');
export const TaskIcon = createIcon('task');
export const ListIcon = createIcon('list');
export const TableIcon = createIcon('table_chart');
export const PageIcon = createIcon('description');
export const PieChartIcon = createIcon('pie_chart');
export const BoxCubeIcon = createIcon('deployed_code');
export const PlugInIcon = createIcon('extension');
export const DocsIcon = createIcon('description');
export const MailIcon = createIcon('mail');
export const HorizontaLDots = createIcon('more_horiz');
export const ChatIcon = createIcon('chat');
export const MoreDotIcon = createIcon('more_vert');
export const AlertHexaIcon = createIcon('warning');
export const ErrorHexaIcon = createIcon('error');
